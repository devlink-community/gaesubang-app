import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/notification/domain/model/app_notification.dart';

abstract interface class NotificationRepository {
  /// 알림 목록 조회
  Future<Result<List<AppNotification>>> getNotifications(String userId);

  /// 특정 알림 읽음 처리 - userId 추가
  Future<Result<bool>> markAsRead(String userId, String notificationId);

  /// 모든 알림 읽음 처리
  Future<Result<bool>> markAllAsRead(String userId);

  /// 특정 알림 삭제 - userId 추가
  Future<Result<bool>> deleteNotification(String userId, String notificationId);
}
