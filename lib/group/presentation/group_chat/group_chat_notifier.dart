// lib/group/presentation/group_chat/group_chat_notifier.dart
import 'dart:async';

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

part 'group_chat_notifier.g.dart';

@riverpod
class GroupChatNotifier extends _$GroupChatNotifier {
  late final GetGroupMessagesUseCase _getGroupMessagesUseCase;
  late final SendMessageUseCase _sendMessageUseCase;
  late final GetGroupMessagesStreamUseCase _getGroupMessagesStreamUseCase;
  late final MarkMessagesAsReadUseCase _markMessagesAsReadUseCase;
  late final GetGroupMembersUseCase _getGroupMembersUseCase;

  StreamSubscription? _messagesSubscription;
  Timer? _timer;
  Timer? _searchDebouncer; // 🆕 검색 디바운싱용 타이머

  @override
  GroupChatState build() {
    print('🏗️ GroupChatNotifier build() 호출');

    // 의존성 주입
    _getGroupMessagesUseCase = ref.watch(getGroupMessagesUseCaseProvider);
    _sendMessageUseCase = ref.watch(sendMessageUseCaseProvider);
    _getGroupMessagesStreamUseCase = ref.watch(
      getGroupMessagesStreamUseCaseProvider,
    );
    _markMessagesAsReadUseCase = ref.watch(markMessagesAsReadUseCaseProvider);
    _getGroupMembersUseCase = ref.watch(getGroupMembersUseCaseProvider);

    // 현재 사용자 정보 가져오기
    final currentUser = ref.read(currentUserProvider);
    final currentUserId = currentUser?.id ?? '';

    // 화면 이탈 시 구독 해제
    ref.onDispose(() {
      print('🗑️ GroupChatNotifier dispose - 스트림 구독 해제');
      _messagesSubscription?.cancel();
      _timer?.cancel();
      _searchDebouncer?.cancel(); // 🆕 검색 타이머 해제
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

      // 🆕 멤버 검색 관련 액션 처리
      case SearchMembers(:final query):
        _handleSearchMembers(query);

      case ClearMemberSearch():
        _handleClearMemberSearch();

      case ToggleMemberSearch():
        _handleToggleMemberSearch();
    }
  }

  // 🆕 멤버 검색 처리 (디바운싱 적용)
  void _handleSearchMembers(String query) {
    // 기존 타이머 취소
    _searchDebouncer?.cancel();

    // 즉시 검색어 상태 업데이트 (UI 반응성을 위해)
    state = state.copyWith(memberSearchQuery: query);

    // 검색어가 비어있으면 즉시 처리
    if (query.trim().isEmpty) {
      state = state.copyWith(memberSearchQuery: '');
      return;
    }

    // 300ms 후에 실제 검색 처리 (디바운싱)
    _searchDebouncer = Timer(const Duration(milliseconds: 300), () {
      // 실제로는 상태만 업데이트하면 됨 (getter에서 필터링 처리)
      print('🔍 멤버 검색: "$query" - 필터링된 결과: ${state.filteredMembers.length}개');
    });
  }

  // 🆕 멤버 검색 초기화
  void _handleClearMemberSearch() {
    _searchDebouncer?.cancel();
    state = state.copyWith(
      memberSearchQuery: '',
      isSearchingMembers: false,
    );
    print('🧹 멤버 검색 초기화됨');
  }

  // 🆕 멤버 검색 모드 토글
  void _handleToggleMemberSearch() {
    final newSearchingState = !state.isSearchingMembers;

    state = state.copyWith(
      isSearchingMembers: newSearchingState,
      memberSearchQuery:
          newSearchingState
              ? state.memberSearchQuery
              : '', // 검색 모드 해제 시 검색어도 초기화
    );

    print('🔄 멤버 검색 모드 ${newSearchingState ? "활성화" : "비활성화"}');
  }

  // 그룹 ID 설정 및 초기 데이터 로드
  Future<void> _handleSetGroupId(String groupId) async {
    if (groupId.isEmpty || groupId == state.groupId) return;

    print('📊 Setting group ID in notifier: $groupId');
    state = state.copyWith(groupId: groupId);

    // 메시지 스트림 구독 시작
    await _subscribeToMessages(groupId);

    // 그룹 멤버 목록 로드
    await _handleLoadGroupMembers();

    // 메시지 읽음 상태 업데이트
    await _handleMarkAsRead();
  }

  // 그룹 멤버 목록 로드
  Future<void> _handleLoadGroupMembers() async {
    if (state.groupId.isEmpty) return;

    try {
      // 로딩 상태로 변경
      state = state.copyWith(groupMembersResult: const AsyncValue.loading());

      // 멤버 목록 로드
      final result = await _getGroupMembersUseCase.execute(state.groupId);

      // 결과 반영
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
    // 기존 구독 해제
    _messagesSubscription?.cancel();

    // 새 스트림 구독
    final messagesStream = _getGroupMessagesStreamUseCase.execute(groupId);

    _messagesSubscription = messagesStream.listen(
      (asyncMessages) {
        // 메시지 상태 업데이트
        state = state.copyWith(messagesResult: asyncMessages);

        // 자동 읽음 처리 (필요시)
        if (asyncMessages is AsyncData &&
            asyncMessages.value != null &&
            asyncMessages.value!.isNotEmpty) {
          // 디바운스 적용
          _timer?.cancel();
          _timer = Timer(const Duration(seconds: 1), () async {
            try {
              await _handleMarkAsRead();
            } catch (e, st) {
              debugPrint('❌ GroupChatNotifier: 메시지 스트림 구독 오류: $e\n$st');
            }
          });
        }
      },
      onError: (error) {
        // 에러 처리
        state = state.copyWith(
          errorMessage: '채팅 메시지 스트림 구독 중 오류가 발생했습니다',
          messagesResult: AsyncError(error, StackTrace.current),
        );
      },
    );
  }

  // 메시지 목록 조회
  Future<void> _handleLoadMessages(String groupId) async {
    // 로딩 상태로 변경
    state = state.copyWith(messagesResult: const AsyncValue.loading());

    try {
      // 메시지 로드
      final result = await _getGroupMessagesUseCase.execute(groupId);

      // 결과 반영
      state = state.copyWith(messagesResult: result);
    } catch (e, st) {
      // 에러 처리 추가
      state = state.copyWith(
        messagesResult: AsyncError(e, st),
        errorMessage: '메시지를 불러오는데 실패했습니다',
      );
    }
  }

  // 메시지 전송
  Future<void> _handleSendMessage(String content) async {
    if (content.trim().isEmpty) return;

    try {
      // 전송 중 상태로 변경
      state = state.copyWith(
        sendingStatus: const AsyncValue.loading(),
        currentMessage: '', // 입력 필드 비우기
      );

      // 메시지 전송
      final result = await _sendMessageUseCase.execute(state.groupId, content);

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
      // 오류 발생 시
      state = state.copyWith(
        sendingStatus: AsyncError(e, StackTrace.current),
        errorMessage: '메시지 전송 중 오류가 발생했습니다',
      );
    }
  }

  // 메시지 읽음 처리
  Future<void> _handleMarkAsRead() async {
    if (state.groupId.isEmpty) return;

    try {
      await _markMessagesAsReadUseCase.execute(state.groupId);
    } catch (e) {
      // 읽음 처리 실패는 조용히 무시 (UX에 영향 없음)
      print('메시지 읽음 처리 실패: $e');
    }
  }

  // 입력 메시지 변경
  void _handleMessageChanged(String message) {
    state = state.copyWith(currentMessage: message);
  }
}
