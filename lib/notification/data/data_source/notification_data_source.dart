import '../dto/notification_dto.dart';

abstract interface class NotificationDataSource {
  /// 알림 목록 조회
  Future<List<NotificationDto>> fetchNotifications(String userId);

  /// 특정 알림 읽음 처리 - userId 추가
  Future<bool> markAsRead(String userId, String notificationId);

  /// 모든 알림 읽음 처리
  Future<bool> markAllAsRead(String userId);

  /// 특정 알림 삭제 - userId 추가
  Future<bool> deleteNotification(String userId, String notificationId);
}
