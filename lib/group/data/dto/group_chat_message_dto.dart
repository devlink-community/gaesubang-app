// lib/group/data/dto/group_chat_message_dto.dart
import 'package:devlink_mobile_app/core/utils/firebase_timestamp_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_chat_message_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class GroupChatMessageDto {
  const GroupChatMessageDto({
    this.id,
    this.groupId,
    this.content,
    this.senderId,
    this.senderName,
    this.senderImage,
    this.timestamp,
    this.isRead,
  });

  final String? id;
  final String? groupId;
  final String? content;
  final String? senderId;
  final String? senderName;
  final String? senderImage;
  
  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? timestamp;
  final bool? isRead;

  factory GroupChatMessageDto.fromJson(Map<String, dynamic> json) =>
      _$GroupChatMessageDtoFromJson(json);
  Map<String, dynamic> toJson() => _$GroupChatMessageDtoToJson(this);

  // 필드 업데이트를 위한 copyWith 메서드
  GroupChatMessageDto copyWith({
    String? id,
    String? groupId,
    String? content,
    String? senderId,
    String? senderName,
    String? senderImage,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return GroupChatMessageDto(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderImage: senderImage ?? this.senderImage,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}