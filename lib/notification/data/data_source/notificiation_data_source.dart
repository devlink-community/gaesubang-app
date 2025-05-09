import 'package:devlink_mobile_app/notification/data/dto/notification_dto.dart';

abstract interface class NotificationDataSource {
  /// 알림 목록 조회
  Future<List<NotificationDto>> fetchNotifications(String userId);

  /// 알림 읽음 처리
  Future<bool> markAsRead(String notificationId);

  /// 모든 알림 읽음 처리
  Future<bool> markAllAsRead(String userId);

  /// 알림 삭제
  Future<bool> deleteNotification(String notificationId);
}
