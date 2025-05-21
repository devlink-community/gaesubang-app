// lib/group/presentation/group_chat/group_chat_action.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_chat_action.freezed.dart';

@freezed
sealed class GroupChatAction with _$GroupChatAction {
  // 메시지 목록 조회
  const factory GroupChatAction.loadMessages(String groupId) = LoadMessages;
  
  // 메시지 전송
  const factory GroupChatAction.sendMessage(String content) = SendMessage;
  
  // 메시지 읽음 처리
  const factory GroupChatAction.markAsRead() = MarkAsRead;
  
  // 그룹 ID 설정 (초기화 시)
  const factory GroupChatAction.setGroupId(String groupId) = SetGroupId;
  
  // 텍스트 필드 값 변경
  const factory GroupChatAction.messageChanged(String message) = MessageChanged;
  
  // 그룹 멤버 목록 로드 액션 추가
  const factory GroupChatAction.loadGroupMembers() = LoadGroupMembers;
}