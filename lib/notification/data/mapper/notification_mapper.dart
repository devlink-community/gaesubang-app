import 'package:devlink_mobile_app/notification/data/dto/notification_dto.dart';
import 'package:devlink_mobile_app/notification/domain/model/notification.dart';

// DTO → Model 변환
extension NotificationDtoMapper on NotificationDto {
  AppNotification toModel() {
    return AppNotification(
      id: id ?? '',
      userId: userId ?? '',
      type: _mapTypeStringToEnum(type),
      targetId: targetId ?? '',
      senderName: senderName ?? '',
      createdAt: createdAt ?? DateTime.now(),
      isRead: isRead ?? false,
      description: description,
      imageUrl: imageUrl,
    );
  }

  NotificationType _mapTypeStringToEnum(String? typeStr) {
    switch (typeStr) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'mention':
        return NotificationType.mention;
      default:
        return NotificationType.comment; // 기본값
    }
  }
}

// Model → DTO 변환
extension NotificationModelMapper on AppNotification {
  NotificationDto toDto() {
    return NotificationDto(
      id: id,
      userId: userId,
      type: type.name,
      targetId: targetId,
      senderName: senderName,
      createdAt: createdAt,
      isRead: isRead,
      description: description,
      imageUrl: imageUrl,
    );
  }
}

// List<NotificationDto> → List<Notification> 변환
extension NotificationDtoListMapper on List<NotificationDto>? {
  List<AppNotification> toModelList() =>
      this?.map((dto) => dto.toModel()).toList() ?? [];
}
