import 'package:devlink_mobile_app/notification/domain/model/app_notification.dart';
import 'package:devlink_mobile_app/notification/presentation/components/notification_item.dart';
import 'package:devlink_mobile_app/notification/presentation/notification_action.dart';
import 'package:devlink_mobile_app/notification/presentation/notification_state.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NotificationScreen extends StatelessWidget {
  final NotificationState state;
  final void Function(NotificationAction action) onAction;

  const NotificationScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          if ((state.notifications.valueOrNull?.isNotEmpty ?? false) &&
              state.unreadCount > 0)
            TextButton(
              onPressed:
                  () => onAction(const NotificationAction.markAllAsRead()),
              child: const Text('모두 읽음'),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return state.notifications.when(
      data: (notifications) => _buildNotificationList(notifications),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _buildErrorView(),
    );
  }

  Widget _buildNotificationList(List<AppNotification> notifications) {
    if (notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('알림이 없습니다'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onAction(const NotificationAction.refresh()),
      child: ListView.separated(
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return NotificationItem(
            notification: notification,
            onTap:
                () => onAction(
                  NotificationAction.tapNotification(notification.id),
                ),
            onDelete:
                () => onAction(
                  NotificationAction.deleteNotification(notification.id),
                ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(state.errorMessage ?? '알림을 불러오는데 실패했습니다'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => onAction(const NotificationAction.refresh()),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
