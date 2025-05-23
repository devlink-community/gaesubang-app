// lib/group/presentation/group_chat/group_chat_action.dart

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../ai_assistance/module/group_chat_bot_service.dart';

part 'group_chat_action.freezed.dart';

@freezed
sealed class GroupChatAction with _$GroupChatAction {
  // 기존 액션들
  const factory GroupChatAction.loadMessages(String groupId) = LoadMessages;

  const factory GroupChatAction.sendMessage(String content) = SendMessage;

  const factory GroupChatAction.markAsRead() = MarkAsRead;

  const factory GroupChatAction.setGroupId(String groupId) = SetGroupId;

  const factory GroupChatAction.messageChanged(String message) = MessageChanged;

  const factory GroupChatAction.loadGroupMembers() = LoadGroupMembers;

  const factory GroupChatAction.searchMembers(String query) = SearchMembers;

  const factory GroupChatAction.clearMemberSearch() = ClearMemberSearch;

  const factory GroupChatAction.toggleMemberSearch() = ToggleMemberSearch;

  // 🆕 봇 관련 액션들
  const factory GroupChatAction.setBotType(BotType? botType) = SetBotType;

  const factory GroupChatAction.sendBotMessage({
    required String userMessage,
    required BotType botType,
  }) = SendBotMessage;

  const factory GroupChatAction.toggleBotActive() = ToggleBotActive;

  // 🆕 봇 응답 생성 관련
  const factory GroupChatAction.generateBotResponse({
    required String userMessage,
    required BotType botType,
  }) = GenerateBotResponse;
}
