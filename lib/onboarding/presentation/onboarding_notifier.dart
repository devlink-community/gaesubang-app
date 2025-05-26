// lib/onboarding/presentation/onboarding_notifier.dart
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'onboarding_action.dart';
import 'onboarding_state.dart';

part 'onboarding_notifier.g.dart';

@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  OnboardingState build() {
    AppLogger.ui('OnboardingNotifier 초기화 시작');

    // 초기 로딩 시작
    _loadInitialState();

    AppLogger.ui('OnboardingNotifier 초기화 완료');
    return const OnboardingState();
  }

  // 🆕 회원가입 후 온보딩 상태 초기화 메서드
  Future<void> resetOnboardingForNewUser() async {
    try {
      AppLogger.logBanner('신규 사용자 온보딩 상태 초기화 시작');
      final startTime = DateTime.now();

      // 1. SharedPreferences에서 온보딩 완료 상태 제거
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('hasCompletedOnboarding');
      
      AppLogger.logStep(1, 4, 'SharedPreferences 온보딩 상태 제거 완료');

      // 2. 상태를 초기 상태로 리셋
      state = const OnboardingState(
        currentPage: 0,
        notificationPermissionStatus: AsyncLoading(),
        locationPermissionStatus: AsyncLoading(),
        onboardingCompletedStatus: AsyncData(false), // 명시적으로 false 설정
      );
      
      AppLogger.logStep(2, 4, '온보딩 상태 초기화 완료');

      // 3. 권한 상태 다시 확인
      await _checkPermissions();
      
      AppLogger.logStep(3, 4, '권한 상태 재확인 완료');

      // 4. 초기 상태 다시 로드
      await _loadInitialState();
      
      AppLogger.logStep(4, 4, '초기 상태 재로딩 완료');

      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('신규 사용자 온보딩 초기화', duration);
      
      AppLogger.logBox(
        '신규 사용자 온보딩 초기화 완료',
        '소요시간: ${duration.inMilliseconds}ms\n상태: 온보딩 미완료로 설정됨',
      );
    } catch (e, st) {
      AppLogger.error('신규 사용자 온보딩 초기화 실패', error: e, stackTrace: st);
      
      // 실패 시에도 최소한 상태는 리셋
      state = const OnboardingState(
        currentPage: 0,
        notificationPermissionStatus: AsyncError('초기화 실패', StackTrace.empty),
        locationPermissionStatus: AsyncError('초기화 실패', StackTrace.empty),
        onboardingCompletedStatus: AsyncData(false),
      );
    }
  }

  // 🆕 온보딩 상태 강제 새로고침 메서드
  Future<void> refreshOnboardingState() async {
    try {
      AppLogger.info('온보딩 상태 강제 새로고침 시작', tag: 'OnboardingRefresh');
      
      // 로딩 상태로 설정
      state = state.copyWith(
        notificationPermissionStatus: const AsyncLoading(),
        locationPermissionStatus: const AsyncLoading(),
        onboardingCompletedStatus: const AsyncLoading(),
      );

      // 초기 상태 다시 로드
      await _loadInitialState();
      
      AppLogger.info('온보딩 상태 강제 새로고침 완료', tag: 'OnboardingRefresh');
    } catch (e, st) {
      AppLogger.error('온보딩 상태 새로고침 실패', error: e, stackTrace: st);
    }
  }

  // 초기 상태 로드
  Future<void> _loadInitialState() async {
    try {
      AppLogger.logStep(1, 3, '온보딩 초기 상태 로드 시작');
      final startTime = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      final isCompleted = prefs.getBool('hasCompletedOnboarding') ?? false;

      AppLogger.logState('온보딩 상태 확인', {
        'is_completed': isCompleted,
        'storage_key': 'hasCompletedOnboarding',
      });

      AppLogger.logStep(2, 3, '온보딩 완료 상태 업데이트');
      // 온보딩 완료 상태 업데이트
      state = state.copyWith(onboardingCompletedStatus: AsyncData(isCompleted));

      AppLogger.logStep(3, 3, '권한 상태 확인');
      // 권한 상태 확인
      await _checkPermissions();

      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('온보딩 초기 상태 로드', duration);
      AppLogger.ui('온보딩 초기 상태 로드 완료');
    } catch (e, st) {
      AppLogger.error('온보딩 초기 상태 로드 오류', error: e, stackTrace: st);
      state = state.copyWith(onboardingCompletedStatus: AsyncError(e, st));
    }
  }

  Future<void> onAction(OnboardingAction action) async {
    AppLogger.debug('온보딩 액션 처리: ${action.runtimeType}');

    switch (action) {
      case NextPage():
        _handleNextPage();
      case PreviousPage():
        _handlePreviousPage();
      case GoToPage(:final page):
        _handleGoToPage(page);
      case RequestNotificationPermission():
        await _handleRequestNotificationPermission();
      case RequestLocationPermission():
        await _handleRequestLocationPermission();
      case CompleteOnboarding():
        await _handleCompleteOnboarding();
      case CheckPermissions():
        await _checkPermissions();
    }
  }

  void _handleNextPage() {
    AppLogger.ui('다음 페이지로 이동: ${state.currentPage} → ${state.currentPage + 1}');
    state = state.copyWith(currentPage: state.currentPage + 1);
    // 페이지 전환 후 자동 권한 요청
    _requestPermissionForCurrentPage(state.currentPage);
  }

  void _handlePreviousPage() {
    if (state.currentPage > 0) {
      AppLogger.ui(
        '이전 페이지로 이동: ${state.currentPage} → ${state.currentPage - 1}',
      );
      state = state.copyWith(currentPage: state.currentPage - 1);
      // 페이지 전환 후 자동 권한 요청
      _requestPermissionForCurrentPage(state.currentPage);
    } else {
      AppLogger.debug('이전 페이지 이동 불가: 첫 번째 페이지');
    }
  }

  void _handleGoToPage(int page) {
    AppLogger.ui('특정 페이지로 이동: ${state.currentPage} → $page');
    state = state.copyWith(currentPage: page);
    // 페이지 전환 후 자동 권한 요청
    _requestPermissionForCurrentPage(page);
  }

  // 현재 페이지에 따라 자동으로 권한 요청
  Future<void> _requestPermissionForCurrentPage(int page) async {
    AppLogger.logStep(1, 2, '페이지별 자동 권한 요청: 페이지 $page');

    // 딜레이를 주어 페이지 전환 애니메이션이 완료된 후 권한 요청
    await Future.delayed(const Duration(milliseconds: 300));

    switch (page) {
      case 1: // 알림 권한 페이지
        AppLogger.debug('알림 권한 페이지 - 자동 권한 요청 확인');
        // 이미 권한이 허용되지 않은 경우에만 요청
        final notificationStatus = state.notificationPermissionStatus;
        if (notificationStatus is! AsyncData ||
            notificationStatus.value != true) {
          AppLogger.logStep(2, 2, '알림 권한 자동 요청 시작');
          await _handleRequestNotificationPermission();
        } else {
          AppLogger.debug('알림 권한 이미 허용됨 - 자동 요청 건너뜀');
        }
        break;
      case 2: // 위치 권한 페이지
        AppLogger.debug('위치 권한 페이지 - 자동 권한 요청 확인');
        // 이미 권한이 허용되지 않은 경우에만 요청
        final locationStatus = state.locationPermissionStatus;
        if (locationStatus is! AsyncData || locationStatus.value != true) {
          AppLogger.logStep(2, 2, '위치 권한 자동 요청 시작');
          await _handleRequestLocationPermission();
        } else {
          AppLogger.debug('위치 권한 이미 허용됨 - 자동 요청 건너뜀');
        }
        break;
      default:
        AppLogger.debug('권한 요청이 필요하지 않은 페이지: $page');
    }
  }

  Future<void> _handleRequestNotificationPermission() async {
    AppLogger.logBanner('알림 권한 요청 시작');
    final startTime = DateTime.now();

    try {
      state = state.copyWith(
        notificationPermissionStatus: const AsyncLoading(),
      );

      final platform = Platform.isIOS ? 'iOS' : 'Android';
      AppLogger.logState('알림 권한 요청 환경', {
        'platform': platform,
        'is_ios': Platform.isIOS,
        'is_android': Platform.isAndroid,
      });

      if (Platform.isIOS) {
        await _handleiOSNotificationPermission();
      } else {
        await _handleAndroidNotificationPermission();
      }

      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('알림 권한 요청 처리', duration);
    } catch (e, st) {
      AppLogger.error('알림 권한 요청 중 예외 발생', error: e, stackTrace: st);
      state = state.copyWith(notificationPermissionStatus: AsyncError(e, st));
    }
  }

  Future<void> _handleiOSNotificationPermission() async {
    AppLogger.logStep(1, 4, 'iOS 알림 권한 처리 시작');

    // 먼저 현재 권한 상태 확인
    final status = await Permission.notification.status;
    AppLogger.logState('iOS 현재 알림 권한 상태', {
      'status': status.toString(),
      'is_granted': status.isGranted,
      'is_denied': status.isDenied,
      'is_permanently_denied': status.isPermanentlyDenied,
    });

    if (status.isPermanentlyDenied) {
      AppLogger.warning('iOS 알림 권한이 영구적으로 거부됨 - 설정에서 변경 필요');
      // 사용자가 이전에 "허용 안 함"을 선택한 경우
      // 여기서는 상태만 업데이트하고, UI에서 설정으로 이동하는 버튼을 표시해야 함
      state = state.copyWith(
        notificationPermissionStatus: const AsyncData(false),
      );
      return;
    }

    AppLogger.logStep(2, 4, 'iOS 로컬 알림 플러그인 초기화');
    // 아직 결정되지 않았거나 일시적으로 거부된 경우 권한 요청
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // iOS 설정 초기화
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    AppLogger.logStep(3, 4, 'iOS 알림 플러그인 초기화 및 권한 요청');
    // 초기화 및 권한 요청
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: initializationSettingsIOS,
        android: null,
      ),
    );

    // 권한 상태 확인 (iOS 10 이상)
    final iosPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
    final bool? granted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    AppLogger.logStep(4, 4, 'iOS 알림 권한 요청 결과 처리');
    final finalGranted = granted ?? false;
    AppLogger.logState('iOS 알림 권한 요청 완료', {
      'granted': finalGranted,
      'requested_alert': true,
      'requested_badge': true,
      'requested_sound': true,
    });

    state = state.copyWith(
      notificationPermissionStatus: AsyncData(finalGranted),
    );
  }

  Future<void> _handleAndroidNotificationPermission() async {
    AppLogger.logStep(1, 6, 'Android 알림 권한 처리 시작');

    // Android 13 이상에서는 명시적 권한 요청이 필요합니다
    final status = await Permission.notification.request();
    AppLogger.logState('Android 권한 요청 결과 (Permission Handler)', {
      'status': status.toString(),
      'is_granted': status.isGranted,
    });

    AppLogger.logStep(2, 6, 'Android 로컬 알림 플러그인 초기화');
    // 로컬 알림 초기화 (권한 요청 후에 초기화하는 것이 좋습니다)
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    AppLogger.logStep(3, 6, 'Android 알림 채널 설정');
    // Android 채널 설정 - 이 부분이 중요합니다!
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      '중요 알림', // title
      description: '이 채널은 중요한 알림에 사용됩니다.', // description
      importance: Importance.high,
    );

    AppLogger.logStep(4, 6, 'Android 알림 채널 생성');
    // Android 채널 생성
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidPlugin?.createNotificationChannel(channel);

    AppLogger.logStep(5, 6, 'Android 알림 플러그인 전체 초기화');
    // Android 설정 초기화 - 채널 ID 명시
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');

    // iOS 설정도 필요하므로 정의
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    // 전체 초기화
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: initializationSettingsIOS,
        android: initializationSettingsAndroid,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 알림 응답 처리 (옵션)
        AppLogger.debug('알림 응답 처리: ${response.payload}');
      },
    );

    AppLogger.logStep(6, 6, 'Android 테스트 알림 표시');
    // 테스트 알림 표시 (권한이 허용되었는지 확인하기 위해)
    if (status.isGranted) {
      AppLogger.debug('Android 테스트 알림 표시 시도');
      await flutterLocalNotificationsPlugin.show(
        0,
        '알림 권한 테스트',
        '알림이 제대로 표시됩니다!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
          ),
        ),
      );
      AppLogger.ui('Android 테스트 알림 표시 완료');
    } else {
      AppLogger.warning('Android 알림 권한이 거부되어 테스트 알림 표시 건너뜀');
    }

    // 상태 업데이트
    state = state.copyWith(
      notificationPermissionStatus: AsyncData(status.isGranted),
    );

    AppLogger.logBox(
      'Android 알림 권한 처리 완료',
      '권한 상태: ${status.isGranted ? "허용됨" : "거부됨"}',
    );
  }

  Future<void> _handleRequestLocationPermission() async {
    AppLogger.logBanner('위치 권한 요청 시작');
    final startTime = DateTime.now();

    try {
      state = state.copyWith(locationPermissionStatus: const AsyncLoading());

      final platform = Platform.isIOS ? 'iOS' : 'Android';
      AppLogger.logState('위치 권한 요청 환경', {
        'platform': platform,
        'is_ios': Platform.isIOS,
        'is_android': Platform.isAndroid,
      });

      if (Platform.isIOS) {
        await _handleiOSLocationPermission();
      } else {
        await _handleAndroidLocationPermission();
      }

      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('위치 권한 요청 처리', duration);
    } catch (e, st) {
      AppLogger.error('위치 권한 요청 중 예외 발생', error: e, stackTrace: st);
      state = state.copyWith(locationPermissionStatus: AsyncError(e, st));
    }
  }

  Future<void> _handleiOSLocationPermission() async {
    AppLogger.logStep(1, 3, 'iOS 위치 권한 처리 시작');

    // 먼저 권한 상태 확인
    final status = await Permission.location.status;
    AppLogger.logState('iOS 현재 위치 권한 상태', {
      'status': status.toString(),
      'is_granted': status.isGranted,
      'is_permanently_denied': status.isPermanentlyDenied,
    });

    if (status.isPermanentlyDenied) {
      AppLogger.warning('iOS 위치 권한이 영구적으로 거부됨 - 설정에서 변경 필요');
      // 사용자가 이전에 "허용 안 함"을 선택한 경우
      state = state.copyWith(
        locationPermissionStatus: const AsyncData(false),
      );
      return;
    }

    AppLogger.logStep(2, 3, 'iOS Geolocator를 사용하여 위치 권한 요청');
    // Geolocator 패키지를 사용하여 iOS 위치 권한 요청
    LocationPermission permission = await Geolocator.requestPermission();

    bool isGranted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    AppLogger.logStep(3, 3, 'iOS 위치 권한 요청 결과 처리');
    AppLogger.logState('iOS 위치 권한 요청 완료', {
      'permission': permission.toString(),
      'is_granted': isGranted,
      'is_always': permission == LocationPermission.always,
      'is_while_in_use': permission == LocationPermission.whileInUse,
    });

    state = state.copyWith(locationPermissionStatus: AsyncData(isGranted));
  }

  Future<void> _handleAndroidLocationPermission() async {
    AppLogger.logStep(1, 4, 'Android 위치 권한 처리 시작');

    // 먼저 Permission.location을 요청하고
    final status = await Permission.location.request();
    AppLogger.logState('Android 위치 권한 요청 결과 (Permission Handler)', {
      'status': status.toString(),
      'is_granted': status.isGranted,
    });

    AppLogger.logStep(2, 4, 'Android Geolocator로 추가 권한 요청');
    // Geolocator로 권한 요청 (더 강력한 결과를 위해)
    LocationPermission permission = await Geolocator.requestPermission();

    bool isGranted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    AppLogger.logState('Android Geolocator 권한 요청 결과', {
      'permission': permission.toString(),
      'is_granted': isGranted,
      'status_is_granted': status.isGranted,
    });

    AppLogger.logStep(3, 4, 'Android 위치 서비스 활성화 확인');
    // 위치 서비스가 활성화되어 있는지 확인 (옵션)
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    AppLogger.logState('Android 위치 서비스 상태', {
      'service_enabled': serviceEnabled,
      'location_permission_granted': isGranted,
    });

    if (!serviceEnabled) {
      AppLogger.warning('Android 위치 서비스가 비활성화되어 있음');
      // 위치 서비스 켜기 요청하는 로직 추가 가능
    }

    AppLogger.logStep(4, 4, 'Android 위치 권한 상태 업데이트');
    state = state.copyWith(locationPermissionStatus: AsyncData(isGranted));

    AppLogger.logBox(
      'Android 위치 권한 처리 완료',
      '권한 상태: ${isGranted ? "허용됨" : "거부됨"}\n서비스 상태: ${serviceEnabled ? "활성화됨" : "비활성화됨"}',
    );
  }

  Future<void> _handleCompleteOnboarding() async {
    AppLogger.logBanner('온보딩 완료 처리 시작');
    final startTime = DateTime.now();

    try {
      state = state.copyWith(onboardingCompletedStatus: const AsyncLoading());

      AppLogger.logStep(1, 2, '온보딩 완료 상태 저장');
      // 온보딩 완료 상태 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedOnboarding', true);

      AppLogger.logStep(2, 2, '온보딩 완료 상태 업데이트');
      state = state.copyWith(onboardingCompletedStatus: const AsyncData(true));

      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('온보딩 완료 처리', duration);
      AppLogger.logBox('온보딩 완료', '소요시간: ${duration.inMilliseconds}ms');
    } catch (e, st) {
      AppLogger.error('온보딩 완료 처리 중 오류', error: e, stackTrace: st);
      state = state.copyWith(onboardingCompletedStatus: AsyncError(e, st));
    }
  }

  Future<void> _checkPermissions() async {
    AppLogger.debug('권한 상태 확인 시작');
    final startTime = DateTime.now();

    try {
      state = state.copyWith(
        notificationPermissionStatus: const AsyncLoading(),
        locationPermissionStatus: const AsyncLoading(),
      );

      AppLogger.logStep(1, 3, '알림 권한 상태 확인');
      // 알림 권한 확인
      bool notificationGranted = false;
      if (Platform.isIOS) {
        await _checkiOSNotificationPermission();
        final notificationStatus = state.notificationPermissionStatus;
        notificationGranted =
            notificationStatus is AsyncData && notificationStatus.value == true;
      } else {
        final notificationStatus = await Permission.notification.status;
        notificationGranted = notificationStatus.isGranted;
        state = state.copyWith(
          notificationPermissionStatus: AsyncData(notificationGranted),
        );
      }

      AppLogger.logStep(2, 3, '위치 권한 상태 확인');
      // 위치 권한 확인
      bool locationGranted = false;
      if (Platform.isIOS) {
        // iOS에서는 Geolocator로 확인
        LocationPermission locationPermission =
            await Geolocator.checkPermission();
        locationGranted =
            locationPermission == LocationPermission.always ||
            locationPermission == LocationPermission.whileInUse;
      } else {
        final locationStatus = await Permission.location.status;
        locationGranted = locationStatus.isGranted;
      }

      state = state.copyWith(
        locationPermissionStatus: AsyncData(locationGranted),
      );

      AppLogger.logStep(3, 3, '권한 상태 확인 완료');
      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('권한 상태 확인', duration);

      AppLogger.logState('최종 권한 상태', {
        'notification_granted': notificationGranted,
        'location_granted': locationGranted,
        'platform': Platform.isIOS ? 'iOS' : 'Android',
      });
    } catch (e, st) {
      AppLogger.error('권한 상태 확인 중 오류', error: e, stackTrace: st);
      state = state.copyWith(
        notificationPermissionStatus: AsyncError(e, st),
        locationPermissionStatus: AsyncError(e, st),
      );
    }
  }

  Future<void> _checkiOSNotificationPermission() async {
    try {
      // iOS에서는 local_notifications 패키지로 확인
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      final iosPlugin =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
      final settings = await iosPlugin?.getNotificationAppLaunchDetails();
      // iOS에서는 정확한 권한 상태 확인이 어려워, 앱 시작 여부로 대체
      final notificationGranted = settings?.didNotificationLaunchApp ?? false;

      state = state.copyWith(
        notificationPermissionStatus: AsyncData(notificationGranted),
      );

      AppLogger.debug('iOS 알림 권한 상태 확인 완료: $notificationGranted');
    } catch (e, st) {
      AppLogger.warning('iOS 알림 권한 상태 확인 실패', error: e, stackTrace: st);
      state = state.copyWith(
        notificationPermissionStatus: const AsyncData(false),
      );
    }
  }
}