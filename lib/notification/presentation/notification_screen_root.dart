// lib/notification/presentation/notification_screen_root.dart
import 'package:devlink_mobile_app/notification/domain/model/app_notification.dart';
import 'package:devlink_mobile_app/notification/presentation/notification_action.dart';
import 'package:devlink_mobile_app/notification/presentation/notification_notifier.dart';
import 'package:devlink_mobile_app/notification/presentation/notification_screen.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NotificationScreenRoot extends ConsumerWidget {
  const NotificationScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // docs에 맞게 상태와 액션 주입
    final state = ref.watch(notificationNotifierProvider);
    final notifier = ref.watch(notificationNotifierProvider.notifier);

    // 디버깅 로그
    AppLogger.debug(
      '현재 state.notifications 타입: ${state.notifications.runtimeType}',
      tag: 'NotificationScreenRoot',
    );

    return NotificationScreen(
      state: state,
      onAction: (action) async {
        // 액션 처리 (docs 기반)
        if (action is TapNotification) {
          await notifier.onAction(action);
          _navigateToTarget(context, action.notificationId, state);
        } else {
          await notifier.onAction(action);
        }
      },
    );
  }

  // 알림 타겟으로 이동하는 메서드
  void _navigateToTarget(BuildContext context, String notificationId, state) {
    // AsyncData인 경우에만 처리
    if (state.notifications is! AsyncData) return;

    final notifications =
        (state.notifications as AsyncData<List<AppNotification>>).value;

    AppNotification? notification;
    try {
      notification = notifications.firstWhere(
        (notification) => notification.id == notificationId,
      );
    } catch (e) {
      AppLogger.warning(
        '알림을 찾을 수 없습니다: $notificationId',
        tag: 'NotificationScreenRoot',
      );
      return; // 알림을 찾지 못함
    }

    // 알림 타입에 따라 다른 화면으로 이동
    switch (notification.type) {
      case NotificationType.like:
      case NotificationType.comment:
        // 게시글 상세로 이동
        context.push('/community/${notification.targetId}');
        break;
      case NotificationType.follow:
        // 사용자 프로필로 이동
        context.push('/user/${notification.targetId}/profile');
        break;
      case NotificationType.mention:
        // 멘션된 게시글로 이동
        context.push('/community/${notification.targetId}');
        break;
    }
  }
}
