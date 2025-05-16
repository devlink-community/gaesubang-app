import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/notification/domain/model/app_notification.dart';
import 'package:devlink_mobile_app/notification/presentation/components/notification_item.dart';
import 'package:devlink_mobile_app/notification/presentation/notification_action.dart';
import 'package:devlink_mobile_app/notification/presentation/notification_state.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NotificationScreen extends StatefulWidget {
  final NotificationState state;
  final void Function(NotificationAction action) onAction;

  const NotificationScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _showOlderNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('알림', style: AppTextStyles.heading6Bold),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        // actions: [
        //   if ((widget.state.notifications.valueOrNull?.isNotEmpty ?? false) &&
        //       widget.state.unreadCount > 0)
        //     TextButton(
        //       onPressed: () => widget.onAction(const NotificationAction.markAllAsRead()),
        //       child: const Text('모두 읽음'),
        //     ),
        // ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    print('_buildBody 호출됨, 상태: ${widget.state.notifications.runtimeType}');

    // AsyncValue 패턴 매칭
    switch (widget.state.notifications) {
      case AsyncLoading():
        print('로딩 상태 감지됨');
        return const Center(child: CircularProgressIndicator());

      case AsyncError(:final error):
        print('에러 상태 감지됨: $error');
        return _buildErrorView();

      case AsyncData(:final value):
        print('데이터 상태 감지됨: ${value.length}개 알림');
        if (value.isEmpty) {
          return _buildEmptyView();
        }
        return _buildNotificationGroups(value);
    }

    // 기본 반환값 (모든 case를 처리하기 위함)
    return const SizedBox.shrink();
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '알림이 없습니다',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '새로운 알림이 오면 여기에 표시됩니다',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationGroups(List<AppNotification> notifications) {
    final now = DateTime.now();

    // 오늘 알림
    final todayNotifications =
        notifications.where((notification) {
          final diff = now.difference(notification.createdAt);
          return diff.inDays == 0;
        }).toList();

    // 최근 7일 알림 (오늘 제외)
    final recentNotifications =
        notifications.where((notification) {
          final diff = now.difference(notification.createdAt);
          return diff.inDays > 0 && diff.inDays < 7;
        }).toList();

    // 이전 알림
    final olderNotifications =
        notifications.where((notification) {
          final diff = now.difference(notification.createdAt);
          return diff.inDays >= 7;
        }).toList();

    return RefreshIndicator(
      onRefresh:
          () async => widget.onAction(const NotificationAction.refresh()),
      child: ListView(
        padding: const EdgeInsets.only(top: 8),
        children: [
          // 오늘 섹션
          if (todayNotifications.isNotEmpty) ...[
            _buildSectionHeader('오늘'),
            ...todayNotifications.map(
              (notification) => NotificationItem(
                notification: notification,
                showDate: false,
                onTap:
                    () => widget.onAction(
                      NotificationAction.tapNotification(notification.id),
                    ),
                onDelete:
                    () => widget.onAction(
                      NotificationAction.deleteNotification(notification.id),
                    ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 최근 7일 섹션
          if (recentNotifications.isNotEmpty) ...[
            _buildSectionHeader('최근 7일'),
            ...recentNotifications.map(
              (notification) => NotificationItem(
                notification: notification,
                showDate: false, // false로 변경 (상대적 시간 표시)
                onTap:
                    () => widget.onAction(
                      NotificationAction.tapNotification(notification.id),
                    ),
                onDelete:
                    () => widget.onAction(
                      NotificationAction.deleteNotification(notification.id),
                    ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 이전 활동 섹션
          if (olderNotifications.isNotEmpty) ...[
            _buildOlderNotificationsSection(olderNotifications),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildOlderNotificationsSection(
    List<AppNotification> olderNotifications,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이전 활동 토글 버튼
        InkWell(
          onTap: () {
            setState(() {
              _showOlderNotifications = !_showOlderNotifications;
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '이전 활동',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Icon(
                  _showOlderNotifications
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),

        // 펼쳐진 상태일 때만 이전 알림 표시
        if (_showOlderNotifications)
          ...olderNotifications.map(
            (notification) => NotificationItem(
              notification: notification,
              showDate: true,
              onTap:
                  () => widget.onAction(
                    NotificationAction.tapNotification(notification.id),
                  ),
              onDelete:
                  () => widget.onAction(
                    NotificationAction.deleteNotification(notification.id),
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(widget.state.errorMessage ?? '알림을 불러오는데 실패했습니다'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed:
                () => widget.onAction(const NotificationAction.refresh()),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
