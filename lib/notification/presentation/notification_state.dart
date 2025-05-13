import 'package:devlink_mobile_app/notification/domain/model/notification.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'notification_state.freezed.dart';

// ignore_for_file: annotate_overrides
@freezed
class NotificationState with _$NotificationState {
  final AsyncValue<List<Notification>> notifications;
  final int unreadCount;
  final String? errorMessage;

  const NotificationState({
    this.notifications = const AsyncValue.loading(),
    this.unreadCount = 0,
    this.errorMessage,
  });
}
