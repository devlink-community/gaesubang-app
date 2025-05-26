import 'package:devlink_mobile_app/notification/presentation/notification_action.dart';
import 'package:devlink_mobile_app/notification/presentation/notification_notifier.dart';
import 'package:devlink_mobile_app/notification/presentation/notification_screen.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NotificationScreenRoot extends ConsumerWidget {
  const NotificationScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 상태와 액션 핸들러 주입
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
        // 모든 액션을 NotificationNotifier로 위임
        // 네비게이션은 NotificationNotifier에서 처리됨
        await notifier.onAction(action);

        // 액션 처리 로깅
        AppLogger.debug(
          '액션 처리 완료: ${action.runtimeType}',
          tag: 'NotificationScreenRoot',
        );
      },
    );
  }
}
