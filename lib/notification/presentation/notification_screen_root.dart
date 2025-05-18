import 'package:devlink_mobile_app/notification/domain/model/app_notification.dart';
import 'package:devlink_mobile_app/notification/presentation/notification_action.dart';
import 'package:devlink_mobile_app/notification/presentation/notification_notifier.dart';
import 'package:devlink_mobile_app/notification/presentation/notification_screen.dart';
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
    print('ScreenRoot: current state type: ${state.notifications.runtimeType}');

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
    // 해당 알림 찾기
    final notification = state.notifications.valueOrNull?.firstWhere(
      (notification) => notification.id == notificationId,
      orElse: () => null,
    );

    if (notification == null) return;

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
