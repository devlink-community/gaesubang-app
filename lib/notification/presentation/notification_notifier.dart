import 'package:devlink_mobile_app/notification/domain/model/app_notification.dart';
import 'package:devlink_mobile_app/notification/domain/usecase/delete_notification_use_case.dart';
import 'package:devlink_mobile_app/notification/domain/usecase/get_notifications_use_case.dart';
import 'package:devlink_mobile_app/notification/domain/usecase/mark_all_notifications_as_read_use_case.dart';
import 'package:devlink_mobile_app/notification/domain/usecase/mark_notification_as_read_use_case.dart';
import 'package:devlink_mobile_app/notification/module/notification_di.dart';
import 'package:devlink_mobile_app/notification/presentation/notification_action.dart';
import 'package:devlink_mobile_app/notification/presentation/notification_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_notifier.g.dart';

@riverpod
class NotificationNotifier extends _$NotificationNotifier {
  // 의존성
  late final GetNotificationsUseCase _getNotificationsUseCase;
  late final MarkNotificationAsReadUseCase _markAsReadUseCase;
  late final MarkAllNotificationsAsReadUseCase _markAllAsReadUseCase;
  late final DeleteNotificationUseCase _deleteNotificationUseCase;

  // 현재 사용자 ID (실제 구현에서는 인증 서비스에서 가져옴)
  String get _currentUserId => 'testUser'; // 임시 하드코딩 값

  @override
  NotificationState build() {
    // 의존성 주입
    _getNotificationsUseCase = ref.watch(getNotificationsUseCaseProvider);
    _markAsReadUseCase = ref.watch(markNotificationAsReadUseCaseProvider);
    _markAllAsReadUseCase = ref.watch(
      markAllNotificationsAsReadUseCaseProvider,
    );
    _deleteNotificationUseCase = ref.watch(deleteNotificationUseCaseProvider);

    // 초기 데이터 로딩
    _loadNotifications();

    return const NotificationState();
  }

  /// 액션 핸들러 - 모든 사용자 액션의 진입점
  Future<void> onAction(NotificationAction action) async {
    switch (action) {
      case Refresh():
        await _loadNotifications();

      case TapNotification(:final notificationId):
        await _handleTapNotification(notificationId);

      case MarkAsRead(:final notificationId):
        await _markAsRead(notificationId);

      case MarkAllAsRead():
        await _markAllAsRead();

      case DeleteNotification(:final notificationId):
        await _deleteNotification(notificationId);
    }
  }

  /// 알림 목록 로드
  Future<void> _loadNotifications() async {
    // 로딩 상태로 설정
    state = state.copyWith(notifications: const AsyncLoading());

    // UseCase 호출
    final result = await _getNotificationsUseCase.execute(_currentUserId);

    // 상태 업데이트
    switch (result) {
      case AsyncData(:final value):
        // 읽지 않은 알림 개수 계산
        final unreadCount = value.where((n) => !n.isRead).length;
        state = state.copyWith(
          notifications: result,
          unreadCount: unreadCount,
          errorMessage: null,
        );

      case AsyncError(:final error):
        state = state.copyWith(
          notifications: result,
          errorMessage: '알림을 불러오는데 실패했습니다.',
        );

      case AsyncLoading():
        // 이미 위에서 처리됨
        break;
    }
  }

  /// 알림 탭 처리
  Future<void> _handleTapNotification(String notificationId) async {
    // 읽음 처리
    await _markAsRead(notificationId);

    // 여기서 필요한 경우 해당 알림의 타겟으로 내비게이션하는 로직을 추가할 수 있음
    // 예: 게시글 알림이면 게시글 상세로 이동 등
    // 이 부분은 Root에서 처리하도록 설계됨
  }

  /// 단일 알림 읽음 처리
  Future<void> _markAsRead(String notificationId) async {
    final result = await _markAsReadUseCase.execute(notificationId);

    switch (result) {
      case AsyncData(:final value) when value:
        // 성공적으로 읽음 처리됨
        // 현재 상태의 알림 목록 업데이트
        final currentNotifications = state.notifications.valueOrNull;
        if (currentNotifications != null) {
          final updatedNotifications =
              currentNotifications.map((notification) {
                if (notification.id == notificationId && !notification.isRead) {
                  // 알림 읽음 처리 및 읽지 않은 개수 감소
                  return AppNotification(
                    id: notification.id,
                    userId: notification.userId,
                    type: notification.type,
                    targetId: notification.targetId,
                    senderName: notification.senderName,
                    createdAt: notification.createdAt,
                    isRead: true,
                    description: notification.description,
                    imageUrl: notification.imageUrl,
                  );
                }
                return notification;
              }).toList();

          state = state.copyWith(
            notifications: AsyncData(updatedNotifications),
            unreadCount: state.unreadCount - 1,
          );
        }

      case AsyncError(:final error):
        state = state.copyWith(errorMessage: '알림 읽음 처리에 실패했습니다.');

      default:
        // 다른 케이스는 무시
        break;
    }
  }

  /// 모든 알림 읽음 처리
  Future<void> _markAllAsRead() async {
    final result = await _markAllAsReadUseCase.execute(_currentUserId);

    switch (result) {
      case AsyncData(:final value) when value:
        // 성공적으로 모두 읽음 처리됨
        // 현재 상태의 알림 목록 업데이트
        final currentNotifications = state.notifications.valueOrNull;
        if (currentNotifications != null) {
          final updatedNotifications =
              currentNotifications.map((notification) {
                if (!notification.isRead) {
                  return AppNotification(
                    id: notification.id,
                    userId: notification.userId,
                    type: notification.type,
                    targetId: notification.targetId,
                    senderName: notification.senderName,
                    createdAt: notification.createdAt,
                    isRead: true,
                    description: notification.description,
                    imageUrl: notification.imageUrl,
                  );
                }
                return notification;
              }).toList();

          state = state.copyWith(
            notifications: AsyncData(updatedNotifications),
            unreadCount: 0,
          );
        }

      case AsyncError(:final error):
        state = state.copyWith(errorMessage: '알림 읽음 처리에 실패했습니다.');

      default:
        // 다른 케이스는 무시
        break;
    }
  }

  /// 알림 삭제
  Future<void> _deleteNotification(String notificationId) async {
    final result = await _deleteNotificationUseCase.execute(notificationId);

    switch (result) {
      case AsyncData(:final value) when value:
        // 성공적으로 삭제됨
        // 현재 상태의 알림 목록에서 제거
        final currentNotifications = state.notifications.valueOrNull;
        if (currentNotifications != null) {
          // 삭제된 알림을 찾아서 읽지 않은 상태였는지 확인
          final wasUnread = currentNotifications
              .where((n) => n.id == notificationId)
              .any((n) => !n.isRead);

          // 목록에서 해당 알림 제거
          final updatedNotifications =
              currentNotifications
                  .where((notification) => notification.id != notificationId)
                  .toList();

          // unreadCount 업데이트
          final newUnreadCount =
              wasUnread ? state.unreadCount - 1 : state.unreadCount;

          state = state.copyWith(
            notifications: AsyncData(updatedNotifications),
            unreadCount: newUnreadCount,
          );
        }

      case AsyncError(:final error):
        state = state.copyWith(errorMessage: '알림 삭제에 실패했습니다.');

      default:
        // 다른 케이스는 무시
        break;
    }
  }
}
