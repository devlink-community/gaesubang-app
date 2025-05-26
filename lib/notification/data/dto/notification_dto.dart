import 'package:json_annotation/json_annotation.dart';

part 'notification_dto.g.dart';

@JsonSerializable()
class NotificationDto {
  final String? id;
  final String? userId;
  final String? type;
  final String? targetId;
  final String? senderName;
  final String? senderId; // 발송자 ID 필드 추가
  final DateTime? createdAt;
  final bool? isRead;
  final String? description;
  final String? imageUrl;

  const NotificationDto({
    this.id,
    this.userId,
    this.type,
    this.targetId,
    this.senderName,
    this.senderId, // 파라미터 추가
    this.createdAt,
    this.isRead,
    this.description,
    this.imageUrl,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationDtoToJson(this);
}
