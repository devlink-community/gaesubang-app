// lib/group/presentation/group_chat/group_chat_action.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_chat_action.freezed.dart';

/// 그룹 채팅 화면에서 발생하는 사용자 액션들
@freezed
sealed class GroupChatAction with _$GroupChatAction {
  /// 그룹 ID 설정 액션 (초기화 시 사용)
  const factory GroupChatAction.setGroupId(String groupId) = SetGroupId;
  
  /// 메시지 목록 로드 액션
  const factory GroupChatAction.loadMessages() = LoadMessages;
  
  /// 이전 메시지 더 로드 액션 (페이지네이션)
  const factory GroupChatAction.loadMoreMessages() = LoadMoreMessages;
  
  /// 메시지 전송 액션
  const factory GroupChatAction.sendMessage(String content) = SendMessage;
  
  /// 메시지 삭제 액션 (향후 구현)
  const factory GroupChatAction.deleteMessage(String messageId) = DeleteMessage;
  
  /// 이미지 첨부 액션 (향후 구현)
  const factory GroupChatAction.attachImage(String imagePath) = AttachImage;
}