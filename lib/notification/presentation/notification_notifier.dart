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
import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/notification/service/fcm_service.dart';
import 'package:devlink_mobile_app/notification/service/fcm_token_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
  late final FCMTokenService _fcmTokenService;

  // 스트림 구독 관리
  StreamSubscription? _fcmSubscription;
  ProviderSubscription? _authSubscription;

  // 마지막으로 토큰을 등록한 사용자 ID (중복 방지)
  String? _lastRegisteredUserId;

  String? get _currentUserId {
    debugPrint('=== _currentUserId 호출됨 ===');
    final authStateAsync = ref.read(authStateProvider);

    return authStateAsync.when(
      data: (authState) {
        debugPrint('authState 데이터: $authState');
        switch (authState) {
          case Authenticated(user: final member):
            debugPrint('인증된 사용자 발견: ${member.uid}');
            return member.uid;
          case _:
            debugPrint('인증되지 않은 상태');
            return null;
        }
      },
      loading: () {
        debugPrint('authState 로딩 중...');
        return null;
      },
      error: (error, stackTrace) {
        debugPrint('authState 에러: $error');
        return null;
      },
    );
  }

  @override
  NotificationState build() {
    debugPrint('=== NotificationNotifier.build() 호출됨 ===');

    // 의존성 주입
    _getNotificationsUseCase = ref.watch(getNotificationsUseCaseProvider);
    _markAsReadUseCase = ref.watch(markNotificationAsReadUseCaseProvider);
    _markAllAsReadUseCase = ref.watch(
      markAllNotificationsAsReadUseCaseProvider,
    );
    _deleteNotificationUseCase = ref.watch(deleteNotificationUseCaseProvider);
    _fcmService = ref.watch(fcmServiceProvider);
    _fcmTokenService = ref.watch(fcmTokenServiceProvider);

    debugPrint('의존성 주입 완료');

    // FCM 알림 클릭 이벤트 구독
    _subscribeToFCMEvents();
    debugPrint('FCM 이벤트 구독 완료');

    // 인증 상태 변화 감지 및 처리
    _setupAuthStateListener();
    debugPrint('인증 상태 리스너 설정 완료');

    // 초기 인증 상태 확인 및 알림 로딩
    _checkInitialAuthStateAndLoadNotifications();

    // 리소스 정리
    ref.onDispose(() {
      debugPrint('NotificationNotifier dispose됨');
      _fcmSubscription?.cancel();
      _authSubscription?.close();
    });

    debugPrint('초기 상태 반환: NotificationState()');
    return const NotificationState();
  }

  /// 인증 상태 변화 리스너 설정
  void _setupAuthStateListener() {
    _authSubscription = ref.listen(authStateProvider, (previous, next) {
      debugPrint('=== authStateProvider 변화 감지됨 ===');
      debugPrint('이전 상태: $previous');
      debugPrint('현재 상태: $next');

      next.when(
        data: (authState) {
          debugPrint('authState 데이터: $authState');
          switch (authState) {
            case Authenticated(user: final member):
              debugPrint('로그인 상태 감지 - 사용자: ${member.nickname}');
              _handleUserLogin(member.uid, member.nickname);
            case Unauthenticated():
              debugPrint('로그아웃 상태 감지');
              _handleUserLogout();
            case Loading():
              debugPrint('로딩 상태');
              break;
          }
        },
        loading: () {
          debugPrint('authState 로딩 중...');
        },
        error: (error, stackTrace) {
          debugPrint('authState 에러: $error');
          _handleAuthError();
        },
      );
    });
  }

  /// 사용자 로그인 처리
  Future<void> _handleUserLogin(String userId, String nickname) async {
    debugPrint('=== 사용자 로그인 처리 시작 ===');
    debugPrint('사용자 ID: $userId');
    debugPrint('닉네임: $nickname');

    try {
      // 1. FCM 토큰 등록 (중복 방지)
      await _registerFCMTokenIfNeeded(userId);

      // 2. FCM 서비스 진단 (디버깅용)
      await _fcmTokenService.diagnoseService(userId);

      // 3. 알림 목록 로딩
      Future.microtask(() {
        debugPrint('microtask에서 알림 refresh 액션 호출');
        onAction(const NotificationAction.refresh());
      });

      debugPrint('✅ 사용자 로그인 처리 완료');
    } catch (e) {
      debugPrint('❌ 사용자 로그인 처리 실패: $e');
    }
  }

  /// 사용자 로그아웃 처리
  Future<void> _handleUserLogout() async {
    debugPrint('=== 사용자 로그아웃 처리 시작 ===');

    try {
      // 1. 알림 상태 초기화
      state = const NotificationState(
        notifications: AsyncData([]),
        unreadCount: 0,
      );

      // 2. 등록된 사용자 ID 초기화
      _lastRegisteredUserId = null;

      debugPrint('✅ 사용자 로그아웃 처리 완료');
    } catch (e) {
      debugPrint('❌ 사용자 로그아웃 처리 실패: $e');
    }
  }

  /// 인증 에러 처리
  void _handleAuthError() {
    debugPrint('=== 인증 에러 처리 ===');

    state = const NotificationState(
      notifications: AsyncData([]),
      unreadCount: 0,
      errorMessage: '인증 오류가 발생했습니다.',
    );
  }

  /// FCM 토큰 등록 (중복 방지)
  Future<void> _registerFCMTokenIfNeeded(String userId) async {
    // 이미 등록된 사용자인 경우 스킵
    if (_lastRegisteredUserId == userId) {
      debugPrint('이미 등록된 사용자 - FCM 토큰 등록 스킵');
      return;
    }

    try {
      debugPrint('=== FCM 토큰 등록 시작 ===');

      // 1. 권한 확인
      final hasPermission = await _fcmTokenService.hasNotificationPermission();
      if (!hasPermission) {
        debugPrint('FCM 권한이 없음 - 권한 요청');
        final granted = await _fcmTokenService.requestNotificationPermission();
        if (!granted) {
          debugPrint('⚠️ FCM 권한 거부됨');
          return;
        }
      }

      // 2. 토큰 등록
      await _fcmTokenService.registerDeviceToken(userId);

      // 3. 등록 완료 마킹
      _lastRegisteredUserId = userId;

      debugPrint('✅ FCM 토큰 등록 완료');
    } catch (e) {
      debugPrint('❌ FCM 토큰 등록 실패: $e');
    }
  }

  /// 초기 인증 상태를 확인하고 필요시 알림을 로딩
  void _checkInitialAuthStateAndLoadNotifications() {
    debugPrint('=== 초기 인증 상태 확인 시작 ===');

    Future.microtask(() {
      final authStateAsync = ref.read(authStateProvider);
      debugPrint('현재 authState: $authStateAsync');

      authStateAsync.when(
        data: (authState) {
          debugPrint('초기 authState 데이터: $authState');
          switch (authState) {
            case Authenticated(user: final member):
              debugPrint('초기 상태에서 인증된 사용자 감지: ${member.nickname}');
              _handleUserLogin(member.uid, member.nickname);
            case _:
              debugPrint('초기 상태에서 비인증 상태');
              _handleUserLogout();
          }
        },
        loading: () {
          debugPrint('초기 authState 로딩 중...');
        },
        error: (error, stackTrace) {
          debugPrint('초기 authState 에러: $error');
          _handleAuthError();
        },
      );
    });
  }

  /// FCM 이벤트 구독
  void _subscribeToFCMEvents() {
    _fcmSubscription = _fcmService.onNotificationTap.listen((payload) {
      debugPrint('=== FCM 알림 탭 이벤트 수신 ===');
      debugPrint('알림 타입: ${payload.type}');
      debugPrint('타겟 ID: ${payload.targetId}');

      // 알림 목록 새로고침
      onAction(const NotificationAction.refresh());

      // 특정 알림 처리는 Root에서 처리하도록 위임
      // 여기서는 단순히 알림 목록만 새로고침
    });
  }

  /// 액션 핸들러 - 모든 사용자 액션의 진입점
  Future<void> onAction(NotificationAction action) async {
    debugPrint('=== NotificationAction 수신 ===');
    debugPrint('액션 타입: ${action.runtimeType}');

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

  /// 알림 목록 로딩
  Future<void> _loadNotifications() async {
    debugPrint('=== _loadNotifications 시작 ===');
    debugPrint('현재 환경: ${AppConfig.useMockAuth ? "Mock" : "Firebase"}');

    final currentUserId = _currentUserId;
    debugPrint('현재 사용자 ID: $currentUserId');

    if (currentUserId == null) {
      debugPrint('사용자 ID가 null - 빈 상태로 설정');
      state = const NotificationState(
        notifications: AsyncData([]),
        unreadCount: 0,
      );
      return;
    }

    debugPrint('알림 로딩 시작: userId=$currentUserId');

    // 로딩 상태로 설정
    state = NotificationState(
      notifications: const AsyncLoading(),
      unreadCount: state.unreadCount,
      errorMessage: state.errorMessage,
    );
    debugPrint('로딩 상태로 변경됨');

    try {
      debugPrint('UseCase 호출 중...');
      final result = await _getNotificationsUseCase.execute(currentUserId);
      debugPrint('UseCase 결과 타입: ${result.runtimeType}');
      debugPrint('UseCase 결과: $result');

      if (result is AsyncData) {
        final notifications = result.value ?? [];
        final unreadCount = notifications.where((n) => !n.isRead).length;
        debugPrint(
          '알림 데이터 로드 성공: ${notifications.length}개, 읽지않음: $unreadCount개',
        );

        state = NotificationState(
          notifications: AsyncData(notifications),
          unreadCount: unreadCount,
          errorMessage: null,
        );

        debugPrint('상태 업데이트 완료: ${state.notifications.runtimeType}');
      } else if (result is AsyncError) {
        debugPrint('UseCase에서 에러 반환: ${result.error}');
        state = NotificationState(
          notifications: AsyncError(result.error!, result.stackTrace!),
          unreadCount: state.unreadCount,
          errorMessage: '알림을 불러오는데 실패했습니다.',
        );
      }
    } catch (e, stack) {
      debugPrint('예외 발생: $e');
      debugPrint('스택 트레이스: $stack');

      state = NotificationState(
        notifications: AsyncError(e, stack),
        unreadCount: state.unreadCount,
        errorMessage: '알림을 불러오는데 실패했습니다: $e',
      );
    }
  }

  /// 알림 탭 처리
  Future<void> _handleTapNotification(String notificationId) async {
    debugPrint('=== 알림 탭 처리: $notificationId ===');

    // 읽음 처리
    await _markAsRead(notificationId);

    // 여기서 필요한 경우 해당 알림의 타겟으로 내비게이션하는 로직을 추가할 수 있음
    // 예: 게시글 알림이면 게시글 상세로 이동 등
    // 이 부분은 Root에서 처리하도록 설계됨
  }

  /// 단일 알림 읽음 처리
  Future<void> _markAsRead(String notificationId) async {
    debugPrint('=== 단일 알림 읽음 처리: $notificationId ===');

    try {
      final result = await _markAsReadUseCase.execute(notificationId);

      switch (result) {
        case AsyncData(:final value) when value:
          debugPrint('✅ 알림 읽음 처리 성공');
          _updateNotificationReadStatus(notificationId, true);

        case AsyncError(:final error):
          debugPrint('❌ 알림 읽음 처리 실패: $error');
          state = state.copyWith(errorMessage: '알림 읽음 처리에 실패했습니다.');

        default:
          debugPrint('알림 읽음 처리 결과를 알 수 없음');
          break;
      }
    } catch (e) {
      debugPrint('❌ 알림 읽음 처리 예외: $e');
      state = state.copyWith(errorMessage: '알림 읽음 처리 중 오류가 발생했습니다.');
    }
  }

  /// 모든 알림 읽음 처리
  Future<void> _markAllAsRead() async {
    debugPrint('=== 모든 알림 읽음 처리 ===');

    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      debugPrint('사용자 ID가 null - 모든 읽음 처리 불가');
      return;
    }

    try {
      final result = await _markAllAsReadUseCase.execute(currentUserId);

      switch (result) {
        case AsyncData(:final value) when value:
          debugPrint('✅ 모든 알림 읽음 처리 성공');
          _updateAllNotificationsReadStatus();

        case AsyncError(:final error):
          debugPrint('❌ 모든 알림 읽음 처리 실패: $error');
          state = state.copyWith(errorMessage: '모든 알림 읽음 처리에 실패했습니다.');

        default:
          debugPrint('모든 알림 읽음 처리 결과를 알 수 없음');
          break;
      }
    } catch (e) {
      debugPrint('❌ 모든 알림 읽음 처리 예외: $e');
      state = state.copyWith(errorMessage: '모든 알림 읽음 처리 중 오류가 발생했습니다.');
    }
  }

  /// 알림 삭제
  Future<void> _deleteNotification(String notificationId) async {
    debugPrint('=== 알림 삭제: $notificationId ===');

    try {
      final result = await _deleteNotificationUseCase.execute(notificationId);

      switch (result) {
        case AsyncData(:final value) when value:
          debugPrint('✅ 알림 삭제 성공');
          _removeNotificationFromState(notificationId);

        case AsyncError(:final error):
          debugPrint('❌ 알림 삭제 실패: $error');
          state = state.copyWith(errorMessage: '알림 삭제에 실패했습니다.');

        default:
          debugPrint('알림 삭제 결과를 알 수 없음');
          break;
      }
    } catch (e) {
      debugPrint('❌ 알림 삭제 예외: $e');
      state = state.copyWith(errorMessage: '알림 삭제 중 오류가 발생했습니다.');
    }
  }

  /// 특정 알림의 읽음 상태 업데이트
  void _updateNotificationReadStatus(String notificationId, bool isRead) {
    final currentNotifications = state.notifications.valueOrNull;
    if (currentNotifications == null) return;

    bool wasUnread = false;
    final updatedNotifications =
        currentNotifications.map((notification) {
          if (notification.id == notificationId) {
            if (!notification.isRead && isRead) {
              wasUnread = true;
            }
            return AppNotification(
              id: notification.id,
              userId: notification.userId,
              type: notification.type,
              targetId: notification.targetId,
              senderName: notification.senderName,
              createdAt: notification.createdAt,
              isRead: isRead,
              description: notification.description,
              imageUrl: notification.imageUrl,
            );
          }
          return notification;
        }).toList();

    final newUnreadCount =
        wasUnread
            ? (state.unreadCount > 0 ? state.unreadCount - 1 : 0)
            : state.unreadCount;

    state = state.copyWith(
      notifications: AsyncData(updatedNotifications),
      unreadCount: newUnreadCount,
    );
  }

  /// 모든 알림의 읽음 상태 업데이트
  void _updateAllNotificationsReadStatus() {
    final currentNotifications = state.notifications.valueOrNull;
    if (currentNotifications == null) return;

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

  /// 상태에서 알림 제거
  void _removeNotificationFromState(String notificationId) {
    final currentNotifications = state.notifications.valueOrNull;
    if (currentNotifications == null) return;

    // 삭제될 알림이 읽지 않은 상태였는지 확인
    final wasUnread = currentNotifications
        .where((n) => n.id == notificationId)
        .any((n) => !n.isRead);

    // 목록에서 해당 알림 제거
    final updatedNotifications =
        currentNotifications
            .where((notification) => notification.id != notificationId)
            .toList();

    final newUnreadCount =
        wasUnread ? state.unreadCount - 1 : state.unreadCount;

    state = state.copyWith(
      notifications: AsyncData(updatedNotifications),
      unreadCount: newUnreadCount,
    );
  }
}
