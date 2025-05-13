import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_action.freezed.dart';

@freezed
sealed class NotificationAction with _$NotificationAction {
  // 목록 새로고침
  const factory NotificationAction.refresh() = Refresh;

  // 특정 알림 탭
  const factory NotificationAction.tapNotification(String notificationId) =
      TapNotification;

  // 특정 알림 읽음 처리
  const factory NotificationAction.markAsRead(String notificationId) =
      MarkAsRead;

  // 모든 알림 읽음 처리
  const factory NotificationAction.markAllAsRead() = MarkAllAsRead;

  // 특정 알림 삭제
  const factory NotificationAction.deleteNotification(String notificationId) =
      DeleteNotification;
}
