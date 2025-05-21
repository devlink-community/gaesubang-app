// lib/group/data/mapper/group_chat_message_mapper.dart
import 'package:devlink_mobile_app/group/data/dto/group_chat_message_dto.dart';
import 'package:devlink_mobile_app/group/domain/model/chat_message.dart';

/// GroupChatMessageDto → ChatMessage 변환
extension GroupChatMessageDtoMapper on GroupChatMessageDto {
  ChatMessage toModel() {
    return ChatMessage(
      id: id ?? '',
      groupId: groupId ?? '',
      content: content ?? '',
      senderId: senderId ?? '',
      senderName: senderName ?? '',
      senderImage: senderImage,
      timestamp: timestamp ?? DateTime.now(),
      isRead: isRead ?? false,
    );
  }
}

/// ChatMessage → GroupChatMessageDto 변환
extension ChatMessageModelMapper on ChatMessage {
  GroupChatMessageDto toDto() {
    return GroupChatMessageDto(
      id: id,
      groupId: groupId,
      content: content,
      senderId: senderId,
      senderName: senderName,
      senderImage: senderImage,
      timestamp: timestamp,
      isRead: isRead,
    );
  }
}

/// List<GroupChatMessageDto> → List<ChatMessage> 변환
extension GroupChatMessageDtoListMapper on List<GroupChatMessageDto>? {
  List<ChatMessage> toModelList() => this?.map((e) => e.toModel()).toList() ?? [];
}

/// List<ChatMessage> → List<GroupChatMessageDto> 변환
extension ChatMessageModelListMapper on List<ChatMessage> {
  List<GroupChatMessageDto> toDtoList() => map((e) => e.toDto()).toList();
}

/// Map<String, dynamic> → GroupChatMessageDto 변환
extension MapToGroupChatMessageDtoMapper on Map<String, dynamic> {
  GroupChatMessageDto toGroupChatMessageDto() => GroupChatMessageDto.fromJson(this);
}