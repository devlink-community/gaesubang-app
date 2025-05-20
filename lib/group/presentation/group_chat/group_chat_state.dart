// lib/group/presentation/group_chat/group_chat_state.dart

import 'package:devlink_mobile_app/group/domain/model/chat_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'group_chat_state.freezed.dart';

/// 그룹 채팅 화면 상태
@freezed
class GroupChatState with _$GroupChatState {
  const GroupChatState({
    this.groupId = '',  // 기본값을 직접 지정
    this.groupName = '',
    this.currentUserId = '',
    this.messages = const AsyncValue.loading(),
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.lastMessageId,  // 기본값이 필요 없는 nullable 필드
    this.isSending = false,
    this.errorMessage,  // 기본값이 필요 없는 nullable 필드
  });
  
  final String groupId;
  final String groupName;
  final String currentUserId;
  final AsyncValue<List<ChatMessage>> messages;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final String? lastMessageId;
  final bool isSending;
  final String? errorMessage;
}