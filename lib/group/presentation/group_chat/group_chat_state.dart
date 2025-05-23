// lib/group/presentation/group_chat/group_chat_state.dart
import 'package:devlink_mobile_app/group/domain/model/chat_message.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../ai_assistance/module/group_chat_bot_service.dart';

part 'group_chat_state.freezed.dart';

@freezed
class GroupChatState with _$GroupChatState {
  const GroupChatState({
    // 기존 필드들
    this.groupId = '',
    this.messagesResult = const AsyncValue.loading(),
    this.sendingStatus = const AsyncValue.data(null),
    this.currentMessage = '',
    this.errorMessage,
    this.groupMembersResult = const AsyncValue.loading(),
    this.currentUserId = '',
    this.memberSearchQuery = '',
    this.isSearchingMembers = false,

    // 🆕 봇 관련 필드들
    this.activeBotType,
    this.isBotActive = false,
    this.botResponseStatus = const AsyncValue.data(null),
    this.lastBotInteraction,
    this.botMessageHistory = const [],
  });

  // 기존 필드들
  final String groupId;
  final AsyncValue<List<ChatMessage>> messagesResult;
  final AsyncValue<void> sendingStatus;
  final String currentMessage;
  final String? errorMessage;
  final AsyncValue<List<GroupMember>> groupMembersResult;
  final String currentUserId;
  final String memberSearchQuery;
  final bool isSearchingMembers;

  // 🆕 봇 관련 필드들
  final BotType? activeBotType; // 현재 활성화된 봇 타입
  final bool isBotActive; // 봇 활성화 상태
  final AsyncValue<void> botResponseStatus; // 봇 응답 생성 상태
  final DateTime? lastBotInteraction; // 마지막 봇 상호작용 시간
  final List<ChatMessage> botMessageHistory; // 봇 메시지 히스토리 (컨텍스트용)

  // 🆕 필터링된 멤버 목록을 반환하는 getter (기존)
  List<GroupMember> get filteredMembers {
    if (groupMembersResult case AsyncData(:final value)) {
      if (memberSearchQuery.isEmpty) {
        return value;
      }

      final query = memberSearchQuery.toLowerCase();
      return value.where((member) {
        return member.userName.toLowerCase().contains(query);
      }).toList();
    }
    return [];
  }

  // 🆕 봇이 응답해야 하는지 확인하는 getter
  bool get shouldBotRespond {
    if (!isBotActive || activeBotType == null || currentMessage.isEmpty) {
      return false;
    }

    final lowerMessage = currentMessage.toLowerCase();

    // 봇 멘션 패턴들
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

  // 🔧 수정: 최근 봇 메시지 히스토리 가져오기 (컨텍스트용)
  List<ChatMessage> get recentBotContext {
    if (messagesResult case AsyncData(:final value)) {
      // 최근 10개 메시지에서 봇과 관련된 대화만 추출
      return value
          .take(10)
          .where(
            (msg) =>
                msg.senderId.startsWith('bot_') ||
                _containsBotMention(msg.content),
          )
          .toList();
    }
    return botMessageHistory;
  }

  // 🆕 봇 멘션 포함 여부 확인 헬퍼 메서드
  bool _containsBotMention(String content) {
    final lowerContent = content.toLowerCase();
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
      (pattern) => lowerContent.contains(pattern.toLowerCase()),
    );
  }

  // 🆕 봇 상태 요약 getter
  String get botStatusText {
    if (!isBotActive || activeBotType == null) {
      return '봇이 비활성화됨';
    }

    switch (botResponseStatus) {
      case AsyncLoading():
        return '${activeBotType!.emoji} 응답 생성 중...';
      case AsyncError():
        return '${activeBotType!.emoji} 응답 생성 실패';
      case AsyncData():
      default:
        return '${activeBotType!.emoji} ${activeBotType!.displayName} 활성화됨';
    }
  }

  // 🆕 봇 메시지 개수 getter
  int get botMessageCount {
    if (messagesResult case AsyncData(:final value)) {
      return value.where((msg) => msg.senderId.startsWith('bot_')).length;
    }
    return 0;
  }
}
