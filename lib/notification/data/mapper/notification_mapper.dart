import 'package:devlink_mobile_app/notification/data/dto/notification_dto.dart';
import 'package:devlink_mobile_app/notification/domain/model/app_notification.dart';

// DTO → Model 변환
extension NotificationDtoMapper on NotificationDto {
  AppNotification toModel() {
    return AppNotification(
      id: id ?? '',
      userId: userId ?? '',
      type: _mapTypeStringToEnum(type),
      targetId: targetId ?? '',
      senderName: senderName ?? '',
      senderId: _extractSafeSenderId(), // 안전한 senderId 추출
      createdAt: createdAt ?? DateTime.now(),
      isRead: isRead ?? false,
      description: description,
      imageUrl: imageUrl,
    );
  }

  /// 안전한 senderId 추출 로직
  /// 1. DTO의 senderId 필드 확인
  /// 2. 값이 유효하면 trim해서 반환
  /// 3. 없거나 비어있으면 null 반환 (AppNotification.safeSenderId에서 fallback 처리)
  String? _extractSafeSenderId() {
    // DTO의 senderId 필드 확인
    if (senderId != null && senderId!.trim().isNotEmpty) {
      final trimmedSenderId = senderId!.trim();

      // 'unknown' 같은 무의미한 값 필터링
      if (trimmedSenderId != 'unknown' &&
          trimmedSenderId != 'null' &&
          trimmedSenderId != userId) {
        // userId와 같으면 의미없음
        return trimmedSenderId;
      }
    }

    // 유효한 senderId가 없으면 null 반환
    // AppNotification.safeSenderId에서 userId로 fallback 처리됨
    return null;
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
      senderId: senderId, // senderId 필드 추가
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
