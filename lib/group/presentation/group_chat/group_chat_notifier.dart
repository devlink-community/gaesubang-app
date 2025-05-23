// lib/group/presentation/group_chat/group_chat_notifier.dart
import 'dart:async';

import 'package:devlink_mobile_app/ai_assistance/module/ai_client_di.dart';
import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_group_members_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_group_messages_stream_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/get_group_messages_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/mark_messages_as_read_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/send_message_use_case.dart';
import 'package:devlink_mobile_app/group/module/group_di.dart';
import 'package:devlink_mobile_app/group/presentation/group_chat/group_chat_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_chat/group_chat_state.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../ai_assistance/module/group_chat_bot_service.dart';
import '../../domain/usecase/send_bot_use_case.dart';

part 'group_chat_notifier.g.dart';

@riverpod
class GroupChatNotifier extends _$GroupChatNotifier {
  late final GetGroupMessagesUseCase _getGroupMessagesUseCase;
  late final SendMessageUseCase _sendMessageUseCase;
  late final SendBotMessageUseCase _sendBotMessageUseCase;
  late final GetGroupMessagesStreamUseCase _getGroupMessagesStreamUseCase;
  late final MarkMessagesAsReadUseCase _markMessagesAsReadUseCase;
  late final GetGroupMembersUseCase _getGroupMembersUseCase;

  late final GroupChatbotService _chatbotService;

  StreamSubscription? _messagesSubscription;
  Timer? _timer;
  Timer? _searchDebouncer;
  Timer? _botResponseTimer;

  @override
  GroupChatState build() {
    print('🏗️ GroupChatNotifier build() 호출');

    // 의존성 주입
    _getGroupMessagesUseCase = ref.watch(getGroupMessagesUseCaseProvider);
    _sendMessageUseCase = ref.watch(sendMessageUseCaseProvider);
    _sendBotMessageUseCase = ref.watch(sendBotMessageUseCaseProvider);
    _getGroupMessagesStreamUseCase = ref.watch(
      getGroupMessagesStreamUseCaseProvider,
    );
    _markMessagesAsReadUseCase = ref.watch(markMessagesAsReadUseCaseProvider);
    _getGroupMembersUseCase = ref.watch(getGroupMembersUseCaseProvider);

    // 봇 서비스 초기화
    final firebaseAIClient = ref.watch(firebaseAIClientProvider);
    _chatbotService = GroupChatbotService(aiClient: firebaseAIClient);

    // 현재 사용자 정보
    final currentUser = ref.read(currentUserProvider);
    final currentUserId = currentUser?.id ?? '';

    // 리소스 정리
    ref.onDispose(() {
      print('🗑️ GroupChatNotifier dispose');
      _messagesSubscription?.cancel();
      _timer?.cancel();
      _searchDebouncer?.cancel();
      _botResponseTimer?.cancel();
    });

    return GroupChatState(currentUserId: currentUserId);
  }

  // 액션 처리
  Future<void> onAction(GroupChatAction action) async {
    print('🎬 GroupChatAction: $action');

    switch (action) {
      case LoadMessages(:final groupId):
        await _handleLoadMessages(groupId);
      case SendMessage(:final content):
        await _handleSendMessage(content);
      case MarkAsRead():
        await _handleMarkAsRead();
      case SetGroupId(:final groupId):
        await _handleSetGroupId(groupId);
      case MessageChanged(:final message):
        _handleMessageChanged(message);
      case LoadGroupMembers():
        await _handleLoadGroupMembers();
      case SearchMembers(:final query):
        _handleSearchMembers(query);
      case ClearMemberSearch():
        _handleClearMemberSearch();
      case ToggleMemberSearch():
        _handleToggleMemberSearch();
      case SetBotType(:final botType):
        _handleSetBotType(botType);
      case SendBotMessage(:final userMessage, :final botType):
        await _handleSendBotMessage(userMessage, botType);
      case ToggleBotActive():
        _handleToggleBotActive();
      case GenerateBotResponse(:final userMessage, :final botType):
        await _handleGenerateBotResponse(userMessage, botType);
    }
  }

  // 봇 타입 설정
  void _handleSetBotType(BotType? botType) {
    if (botType == null) {
      state = state.copyWith(
        activeBotType: null,
        isBotActive: false,
        botResponseStatus: const AsyncValue.data(null),
      );
      print('🤖 봇 비활성화');
    } else {
      state = state.copyWith(
        activeBotType: botType,
        isBotActive: true,
        lastBotInteraction: DateTime.now(),
        botResponseStatus: const AsyncValue.data(null),
      );
      print('🤖 봇 활성화: ${botType.displayName}');
    }
  }

  // 봇 메시지 전송
  Future<void> _handleSendBotMessage(
    String userMessage,
    BotType botType,
  ) async {
    if (state.groupId.isEmpty) return;

    try {
      state = state.copyWith(botResponseStatus: const AsyncValue.loading());

      // 봇 응답 생성
      final botMessage = await _chatbotService.generateBotResponse(
        userMessage: userMessage,
        groupId: state.groupId,
        botType: botType,
        recentMessages: state.recentBotContext,
      );

      // 봇 전용 UseCase로 메시지 전송
      final result = await _sendBotMessageUseCase.execute(
        state.groupId,
        botMessage.content,
        botMessage.senderId,
        botMessage.senderName,
      );

      // 히스토리 업데이트
      final updatedHistory = [...state.botMessageHistory, botMessage];
      if (updatedHistory.length > 20) {
        updatedHistory.removeRange(0, updatedHistory.length - 20);
      }

      state = state.copyWith(
        botResponseStatus: const AsyncValue.data(null),
        lastBotInteraction: DateTime.now(),
        botMessageHistory: updatedHistory,
      );

      if (result is AsyncError) {
        state = state.copyWith(errorMessage: '봇 메시지 전송에 실패했습니다');
      }

      print('🤖 봇 응답 전송 완료: ${botMessage.content.substring(0, 30)}...');
    } catch (e) {
      state = state.copyWith(
        botResponseStatus: AsyncError(e, StackTrace.current),
        errorMessage: '봇 응답 생성 중 오류가 발생했습니다',
      );
      print('❌ 봇 응답 생성 실패: $e');
    }
  }

  // 봇 활성화 토글
  void _handleToggleBotActive() {
    if (state.activeBotType == null) {
      _handleSetBotType(BotType.assistant);
    } else {
      _handleSetBotType(null);
    }
  }

  // 봇 응답 생성 (디바운싱)
  Future<void> _handleGenerateBotResponse(
    String userMessage,
    BotType botType,
  ) async {
    _botResponseTimer?.cancel();
    _botResponseTimer = Timer(const Duration(milliseconds: 1500), () async {
      await _handleSendBotMessage(userMessage, botType);
    });
  }

  // 메시지 전송 (봇 멘션 확인 포함)
  Future<void> _handleSendMessage(String content) async {
    if (content.trim().isEmpty) return;

    try {
      state = state.copyWith(
        sendingStatus: const AsyncValue.loading(),
        currentMessage: '',
      );

      // 일반 메시지 전송
      final result = await _sendMessageUseCase.execute(state.groupId, content);

      // 봇 멘션 확인 및 자동 응답
      if (state.isBotActive &&
          state.activeBotType != null &&
          _shouldBotRespond(content)) {
        print('🤖 봇 멘션 감지, 자동 응답 생성 중...');
        await _handleGenerateBotResponse(content, state.activeBotType!);
      }

      // 결과 처리
      if (result is AsyncError) {
        state = state.copyWith(
          sendingStatus: const AsyncValue.data(null),
          errorMessage: '메시지 전송에 실패했습니다',
        );
      } else {
        state = state.copyWith(
          sendingStatus: const AsyncValue.data(null),
          errorMessage: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        sendingStatus: AsyncError(e, StackTrace.current),
        errorMessage: '메시지 전송 중 오류가 발생했습니다',
      );
    }
  }

  // 봇 응답 여부 확인
  bool _shouldBotRespond(String message) {
    final lowerMessage = message.toLowerCase();
    final mentionPatterns = [
      '@챗봇',
      '@봇',
      '@ai',
      '@어시스턴트',
      '@assistant',
      '@리서처',
      '@researcher',
      '@상담사',
      '@counselor',
    ];
    return mentionPatterns.any(
      (pattern) => lowerMessage.contains(pattern.toLowerCase()),
    );
  }

  // 멤버 검색
  void _handleSearchMembers(String query) {
    _searchDebouncer?.cancel();
    state = state.copyWith(memberSearchQuery: query);

    if (query.trim().isEmpty) {
      state = state.copyWith(memberSearchQuery: '');
      return;
    }

    _searchDebouncer = Timer(const Duration(milliseconds: 300), () {
      print('🔍 멤버 검색: "$query" - 결과: ${state.filteredMembers.length}개');
    });
  }

  void _handleClearMemberSearch() {
    _searchDebouncer?.cancel();
    state = state.copyWith(
      memberSearchQuery: '',
      isSearchingMembers: false,
    );
  }

  void _handleToggleMemberSearch() {
    final newSearchingState = !state.isSearchingMembers;
    state = state.copyWith(
      isSearchingMembers: newSearchingState,
      memberSearchQuery: newSearchingState ? state.memberSearchQuery : '',
    );
  }

  // 그룹 ID 설정 및 초기화
  Future<void> _handleSetGroupId(String groupId) async {
    if (groupId.isEmpty || groupId == state.groupId) return;

    print('📊 그룹 ID 설정: $groupId');
    state = state.copyWith(groupId: groupId);

    await _subscribeToMessages(groupId);
    await _handleLoadGroupMembers();
    await _handleMarkAsRead();
  }

  // 그룹 멤버 로드
  Future<void> _handleLoadGroupMembers() async {
    if (state.groupId.isEmpty) return;

    try {
      state = state.copyWith(groupMembersResult: const AsyncValue.loading());
      final result = await _getGroupMembersUseCase.execute(state.groupId);
      state = state.copyWith(groupMembersResult: result);

      if (result is AsyncData) {
        print('✅ 그룹 멤버 로드 완료: ${result.value?.length}명');
      }
    } catch (e) {
      state = state.copyWith(
        groupMembersResult: AsyncError(e, StackTrace.current),
        errorMessage: '그룹 멤버 목록을 불러오는데 실패했습니다',
      );
    }
  }

  // 메시지 스트림 구독
  Future<void> _subscribeToMessages(String groupId) async {
    _messagesSubscription?.cancel();

    final messagesStream = _getGroupMessagesStreamUseCase.execute(groupId);

    _messagesSubscription = messagesStream.listen(
      (asyncMessages) {
        state = state.copyWith(messagesResult: asyncMessages);

        if (asyncMessages is AsyncData &&
            asyncMessages.value != null &&
            asyncMessages.value!.isNotEmpty) {
          _timer?.cancel();
          _timer = Timer(const Duration(seconds: 1), () async {
            try {
              await _handleMarkAsRead();
            } catch (e, st) {
              debugPrint('❌ 메시지 읽음 처리 오류: $e\n$st');
            }
          });
        }
      },
      onError: (error) {
        state = state.copyWith(
          errorMessage: '채팅 메시지 스트림 구독 중 오류가 발생했습니다',
          messagesResult: AsyncError(error, StackTrace.current),
        );
      },
    );
  }

  // 메시지 로드
  Future<void> _handleLoadMessages(String groupId) async {
    state = state.copyWith(messagesResult: const AsyncValue.loading());

    try {
      final result = await _getGroupMessagesUseCase.execute(groupId);
      state = state.copyWith(messagesResult: result);
    } catch (e, st) {
      state = state.copyWith(
        messagesResult: AsyncError(e, st),
        errorMessage: '메시지를 불러오는데 실패했습니다',
      );
    }
  }

  // 메시지 읽음 처리
  Future<void> _handleMarkAsRead() async {
    if (state.groupId.isEmpty) return;

    try {
      await _markMessagesAsReadUseCase.execute(state.groupId);
    } catch (e) {
      print('메시지 읽음 처리 실패: $e');
    }
  }

  // 메시지 변경
  void _handleMessageChanged(String message) {
    state = state.copyWith(currentMessage: message);
  }
}
