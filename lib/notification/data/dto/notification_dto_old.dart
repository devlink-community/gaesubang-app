import 'package:devlink_mobile_app/core/utils/firebase_timestamp_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification_dto_old.g.dart';

@JsonSerializable()
class NotificationDto {
  final String? id;
  final String? userId;
  final String? type;
  final String? targetId;
  final String? senderName;
  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
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
    this.createdAt,
    this.isRead,
    this.description,
    this.imageUrl,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationDtoToJson(this);
}
