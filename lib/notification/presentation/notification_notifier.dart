import 'dart:async';

import 'package:devlink_mobile_app/core/auth/auth_state.dart';
import 'package:devlink_mobile_app/core/config/app_config.dart';
import 'package:devlink_mobile_app/notification/domain/model/app_notification.dart';
import 'package:devlink_mobile_app/notification/domain/usecase/delete_notification_use_case.dart';
import 'package:devlink_mobile_app/notification/domain/usecase/get_notifications_use_case.dart';
import 'package:devlink_mobile_app/notification/domain/usecase/mark_all_notifications_as_read_use_case.dart';
import 'package:devlink_mobile_app/notification/domain/usecase/mark_notification_as_read_use_case.dart';
import 'package:devlink_mobile_app/notification/module/fcm_di.dart';
import 'package:devlink_mobile_app/notification/module/notification_di.dart';
import 'package:devlink_mobile_app/notification/presentation/notification_action.dart';
import 'package:devlink_mobile_app/notification/presentation/notification_state.dart';
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
=======
>>>>>>> 2e5e6eb3 (fix: notification notifier fcm logic 추가 완료)
=======
>>>>>>> 6e00cb03 (fix: notification notifier fcm logic 추가 완료)
=======
import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
>>>>>>> b67c10c2 (fix: currentUserId 수정 및 fcm 연동을 위한 전체 코드 수정)
import 'package:devlink_mobile_app/notification/service/fcm_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_notifier.g.dart';

@riverpod
class NotificationNotifier extends _$NotificationNotifier {
  // 의존성
  late final GetNotificationsUseCase _getNotificationsUseCase;
  late final MarkNotificationAsReadUseCase _markAsReadUseCase;
  late final MarkAllNotificationsAsReadUseCase _markAllAsReadUseCase;
  late final DeleteNotificationUseCase _deleteNotificationUseCase;
  late final FCMService _fcmService;
  StreamSubscription? _fcmSubscription;

  // _currentUserId getter 수정 - switch 표현식 올바른 사용
  String? get _currentUserId {
    print('=== _currentUserId 호출됨 ===');
    final authStateAsync = ref.read(authStateProvider);

    return authStateAsync.when(
      data: (authState) {
        print('authState 데이터: $authState');
        switch (authState) {
          case Authenticated(user: final member):
            print('인증된 사용자 발견: ${member.uid}');
            return member.uid;
          case _:
            print('인증되지 않은 상태');
            return null;
        }
      },
      loading: () {
        print('authState 로딩 중...');
        return null;
      },
      error: (error, stackTrace) {
        print('authState 에러: $error');
        return null;
      },
    );
  }

  @override
  NotificationState build() {
    print('=== NotificationNotifier.build() 호출됨 ===');

    // 기존 의존성 주입...
    _getNotificationsUseCase = ref.watch(getNotificationsUseCaseProvider);
    _markAsReadUseCase = ref.watch(markNotificationAsReadUseCaseProvider);
    _markAllAsReadUseCase = ref.watch(
      markAllNotificationsAsReadUseCaseProvider,
    );
    _deleteNotificationUseCase = ref.watch(deleteNotificationUseCaseProvider);
    _fcmService = ref.watch(fcmServiceProvider);
<<<<<<< HEAD
<<<<<<< HEAD

    print('의존성 주입 완료');

    // FCM 알림 클릭 이벤트 구독
    _subscribeToFCMEvents();
    print('FCM 이벤트 구독 완료');

    // 초기 인증 상태 확인 및 알림 로딩
    _checkInitialAuthStateAndLoadNotifications();

    // 인증 상태 변화를 감지하여 알림 로딩
    ref.listen(authStateProvider, (previous, next) {
      print('=== authStateProvider 변화 감지됨 ===');
      print('이전 상태: $previous');
      print('현재 상태: $next');

      next.when(
        data: (authState) {
          print('authState 데이터: $authState');
          switch (authState) {
            case Authenticated():
              print('로그인 상태 감지 - 알림 로딩 트리거');
              Future.microtask(() {
                print('microtask에서 refresh 액션 호출');
                onAction(const NotificationAction.refresh());
              });
            case Unauthenticated():
            case Loading():
              print('비로그인/로딩 상태 - 알림 초기화');
              state = const NotificationState(
                notifications: AsyncData([]),
                unreadCount: 0,
              );
          }
        },
        loading: () {
          print('authState 로딩 중...');
        },
        error: (error, stackTrace) {
          print('authState 에러: $error');
          state = const NotificationState(
            notifications: AsyncData([]),
            unreadCount: 0,
          );
        },
      );
    });
    print('authState 리스너 등록 완료');

    ref.onDispose(() {
      print('NotificationNotifier dispose됨');
      _fcmSubscription?.cancel();
    });

    print('초기 상태 반환: NotificationState()');
    return const NotificationState();
  }

  /// 초기 인증 상태를 확인하고 필요시 알림을 로딩
  void _checkInitialAuthStateAndLoadNotifications() {
    print('=== 초기 인증 상태 확인 시작 ===');

    Future.microtask(() {
      final authStateAsync = ref.read(authStateProvider);
      print('현재 authState: $authStateAsync');

      authStateAsync.when(
        data: (authState) {
          print('초기 authState 데이터: $authState');
          switch (authState) {
            case Authenticated(user: final member):
              print('초기 상태에서 인증된 사용자 감지: ${member.nickname}');
              print('초기 알림 로딩 트리거');
              onAction(const NotificationAction.refresh());
            case _:
              print('초기 상태에서 비인증 상태');
              state = const NotificationState(
                notifications: AsyncData([]),
                unreadCount: 0,
              );
          }
        },
        loading: () {
          print('초기 authState 로딩 중...');
        },
        error: (error, stackTrace) {
          print('초기 authState 에러: $error');
          state = const NotificationState(
            notifications: AsyncData([]),
            unreadCount: 0,
          );
        },
      );
    });
  }

=======
=======
>>>>>>> 6e00cb03 (fix: notification notifier fcm logic 추가 완료)

    print('의존성 주입 완료');

    // FCM 알림 클릭 이벤트 구독
    _subscribeToFCMEvents();
    print('FCM 이벤트 구독 완료');

    // 초기 인증 상태 확인 및 알림 로딩
    _checkInitialAuthStateAndLoadNotifications();

    // 인증 상태 변화를 감지하여 알림 로딩
    ref.listen(authStateProvider, (previous, next) {
      print('=== authStateProvider 변화 감지됨 ===');
      print('이전 상태: $previous');
      print('현재 상태: $next');

      next.when(
        data: (authState) {
          print('authState 데이터: $authState');
          switch (authState) {
            case Authenticated():
              print('로그인 상태 감지 - 알림 로딩 트리거');
              Future.microtask(() {
                print('microtask에서 refresh 액션 호출');
                onAction(const NotificationAction.refresh());
              });
            case Unauthenticated():
            case Loading():
              print('비로그인/로딩 상태 - 알림 초기화');
              state = const NotificationState(
                notifications: AsyncData([]),
                unreadCount: 0,
              );
          }
        },
        loading: () {
          print('authState 로딩 중...');
        },
        error: (error, stackTrace) {
          print('authState 에러: $error');
          state = const NotificationState(
            notifications: AsyncData([]),
            unreadCount: 0,
          );
        },
      );
    });
    print('authState 리스너 등록 완료');

    ref.onDispose(() {
      print('NotificationNotifier dispose됨');
      _fcmSubscription?.cancel();
    });

    print('초기 상태 반환: NotificationState()');
    return const NotificationState();
  }

<<<<<<< HEAD
<<<<<<< HEAD
>>>>>>> 2e5e6eb3 (fix: notification notifier fcm logic 추가 완료)
=======
>>>>>>> 6e00cb03 (fix: notification notifier fcm logic 추가 완료)
=======
  /// 초기 인증 상태를 확인하고 필요시 알림을 로딩
  void _checkInitialAuthStateAndLoadNotifications() {
    print('=== 초기 인증 상태 확인 시작 ===');

    Future.microtask(() {
      final authStateAsync = ref.read(authStateProvider);
      print('현재 authState: $authStateAsync');

      authStateAsync.when(
        data: (authState) {
          print('초기 authState 데이터: $authState');
          switch (authState) {
            case Authenticated(user: final member):
              print('초기 상태에서 인증된 사용자 감지: ${member.nickname}');
              print('초기 알림 로딩 트리거');
              onAction(const NotificationAction.refresh());
            case _:
              print('초기 상태에서 비인증 상태');
              state = const NotificationState(
                notifications: AsyncData([]),
                unreadCount: 0,
              );
          }
        },
        loading: () {
          print('초기 authState 로딩 중...');
        },
        error: (error, stackTrace) {
          print('초기 authState 에러: $error');
          state = const NotificationState(
            notifications: AsyncData([]),
            unreadCount: 0,
          );
        },
      );
    });
  }

>>>>>>> b67c10c2 (fix: currentUserId 수정 및 fcm 연동을 위한 전체 코드 수정)
  /// FCM 이벤트 구독
  void _subscribeToFCMEvents() {
    _fcmSubscription = _fcmService.onNotificationTap.listen((payload) {
      // FCM 알림 탭 이벤트 처리
      // 여기서는 간단히 알림 목록을 새로고침하고 특정 알림을 읽음 처리
      onAction(const NotificationAction.refresh());

      // 알림 타입 및 타겟 ID를 기반으로 화면 이동 로직은 Root에서 처리
    });
  }

  /// FCM 토큰 서버 등록
  Future<void> registerFCMToken() async {
    final token = await _fcmService.getToken();
    if (token != null) {
      // TODO: 실제 구현에서는 사용자의 FCM 토큰을 서버에 등록하는 API 호출
      print('FCM 토큰 등록: $token');
    }
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

  // _loadNotifications 메서드에 상세 로그 추가
  Future<void> _loadNotifications() async {
    print('=== _loadNotifications 시작 ===');
    print('현재 환경: ${AppConfig.useMockAuth ? "Mock" : "Firebase"}');

    final currentUserId = _currentUserId;
    print('현재 사용자 ID: $currentUserId');

    if (currentUserId == null) {
      print('사용자 ID가 null - 빈 상태로 설정');
      state = const NotificationState(
        notifications: AsyncData([]),
        unreadCount: 0,
      );
      return;
    }

    print('알림 로딩 시작: userId=$currentUserId');

    // 명시적으로 새 상태 객체 생성
    state = NotificationState(
      notifications: const AsyncLoading(),
      unreadCount: state.unreadCount,
      errorMessage: state.errorMessage,
    );
    print('로딩 상태로 변경됨');

    try {
      print('UseCase 호출 중...');
      final result = await _getNotificationsUseCase.execute(currentUserId);
      print('UseCase 결과 타입: ${result.runtimeType}');
      print('UseCase 결과: $result');

      if (result is AsyncData) {
        final notifications = result.value ?? [];
        final unreadCount = notifications.where((n) => !n.isRead).length;
        print('알림 데이터 로드 성공: ${notifications.length}개, 읽지않음: $unreadCount개');

        // 완전히 새로운 상태 객체 생성
        state = NotificationState(
          notifications: AsyncData(notifications),
          unreadCount: unreadCount,
          errorMessage: null,
        );

        print('상태 업데이트 완료: ${state.notifications.runtimeType}');
      } else if (result is AsyncError) {
        print('UseCase에서 에러 반환: ${result.error}');
        state = NotificationState(
          notifications: AsyncError(result.error!, result.stackTrace!),
          unreadCount: state.unreadCount,
          errorMessage: '알림을 불러오는데 실패했습니다.',
        );
      }
    } catch (e, stack) {
      print('예외 발생: $e');
      print('스택 트레이스: $stack');

      state = NotificationState(
        notifications: AsyncError(e, stack),
        unreadCount: state.unreadCount,
        errorMessage: '알림을 불러오는데 실패했습니다: $e',
      );
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
        final currentNotifications = state.notifications.valueOrNull;
        if (currentNotifications != null) {
          // 읽지 않은 상태였는지 플래그
          bool wasUnread = false;

          // 알림 목록 업데이트
          final updatedNotifications =
              currentNotifications.map((notification) {
                if (notification.id == notificationId) {
                  // 원래 읽지 않은 상태였는지 기록
                  if (!notification.isRead) {
                    wasUnread = true;

                    // 알림 읽음 처리
                    return AppNotification(
                      id: notification.id,
                      userId: notification.userId,
                      type: notification.type,
                      targetId: notification.targetId,
                      senderName: notification.senderName,
                      createdAt: notification.createdAt,
                      isRead: true, // 읽음 상태로 변경
                      description: notification.description,
                      imageUrl: notification.imageUrl,
                    );
                  }
                }
                return notification;
              }).toList();

          // 읽지 않은 알림이었을 경우에만 카운트 감소
          final newUnreadCount =
              wasUnread
                  ? (state.unreadCount > 0 ? state.unreadCount - 1 : 0)
                  : state.unreadCount;

          state = state.copyWith(
            notifications: AsyncData(updatedNotifications),
            unreadCount: newUnreadCount,
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
    final result = await _markAllAsReadUseCase.execute(_currentUserId!);

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
