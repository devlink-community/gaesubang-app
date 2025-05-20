// lib/onboarding/presentation/onboarding_notifier.dart
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_action.dart';
import 'onboarding_state.dart';

part 'onboarding_notifier.g.dart';

@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  OnboardingState build() {
    print('OnboardingNotifier: build() 호출됨');
    // 초기 로딩 시작
    _loadInitialState();
    return const OnboardingState();
  }

  // 초기 상태 로드
  Future<void> _loadInitialState() async {
    try {
      print('OnboardingNotifier: 초기 상태 로드 시작');
      final prefs = await SharedPreferences.getInstance();
      final isCompleted = prefs.getBool('hasCompletedOnboarding') ?? false;

      print('OnboardingNotifier: 온보딩 완료 상태 - $isCompleted');

      // 온보딩 완료 상태 업데이트
      state = state.copyWith(onboardingCompletedStatus: AsyncData(isCompleted));
      print(
        'OnboardingNotifier: 상태 업데이트 완료 - onboardingCompletedStatus: ${state.onboardingCompletedStatus}',
      );

      // 권한 상태 확인
      await _checkPermissions();
    } catch (e, st) {
      print('OnboardingNotifier: 초기 상태 로드 오류 - $e');
      state = state.copyWith(onboardingCompletedStatus: AsyncError(e, st));
    }
  }

  Future<void> onAction(OnboardingAction action) async {
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
    state = state.copyWith(currentPage: state.currentPage + 1);
    // 페이지 전환 후 자동 권한 요청
    _requestPermissionForCurrentPage(state.currentPage);
  }

  void _handlePreviousPage() {
    if (state.currentPage > 0) {
      state = state.copyWith(currentPage: state.currentPage - 1);
      // 페이지 전환 후 자동 권한 요청
      _requestPermissionForCurrentPage(state.currentPage);
    }
  }

  void _handleGoToPage(int page) {
    state = state.copyWith(currentPage: page);
    // 페이지 전환 후 자동 권한 요청
    _requestPermissionForCurrentPage(page);
  }

  // 새로 추가: 현재 페이지에 따라 자동으로 권한 요청
  Future<void> _requestPermissionForCurrentPage(int page) async {
    // 딜레이를 주어 페이지 전환 애니메이션이 완료된 후 권한 요청
    await Future.delayed(const Duration(milliseconds: 300));

    switch (page) {
      case 1: // 알림 권한 페이지
        // 이미 권한이 허용되지 않은 경우에만 요청
        final notificationStatus = state.notificationPermissionStatus;
        if (notificationStatus is! AsyncData ||
            notificationStatus.value != true) {
          await _handleRequestNotificationPermission();
        }
        break;
      case 2: // 위치 권한 페이지
        // 이미 권한이 허용되지 않은 경우에만 요청
        final locationStatus = state.locationPermissionStatus;
        if (locationStatus is! AsyncData || locationStatus.value != true) {
          await _handleRequestLocationPermission();
        }
        break;
    }
  }

  Future<void> _handleRequestNotificationPermission() async {
    try {
      print('알림 권한 요청 시작...');
      state = state.copyWith(
        notificationPermissionStatus: const AsyncLoading(),
      );

      if (Platform.isIOS) {
        // 먼저 현재 권한 상태 확인
        final status = await Permission.notification.status;
        print('iOS 현재 알림 권한 상태: $status');

        if (status.isPermanentlyDenied) {
          // 사용자가 이전에 "허용 안 함"을 선택한 경우
          // 여기서는 상태만 업데이트하고, UI에서 설정으로 이동하는 버튼을 표시해야 함
          print('iOS 알림 권한이 영구적으로 거부됨 - 설정에서 변경 필요');
          state = state.copyWith(
            notificationPermissionStatus: const AsyncData(false),
          );

          // 사용자에게 설정 앱으로 이동하라는 메시지를 표시하기 위한 상태 플래그 설정
          // (이 상태를 UI에서 감지하여 적절한 UI 표시)
          return;
        }

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

        print('iOS 알림 권한 요청 결과: $granted');
        state = state.copyWith(
          notificationPermissionStatus: AsyncData(granted ?? false),
        );
      } else {
        print('Android 알림 권한 요청 중...');

        // Android 13 이상에서는 명시적 권한 요청이 필요합니다
        final status = await Permission.notification.request();
        print('Android 알림 권한 요청 결과 (Permission Handler): ${status.isGranted}');

        // 로컬 알림 초기화 (권한 요청 후에 초기화하는 것이 좋습니다)
        final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
            FlutterLocalNotificationsPlugin();

        // Android 채널 설정 - 이 부분이 중요합니다!
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel', // id
          '중요 알림', // title
          description: '이 채널은 중요한 알림에 사용됩니다.', // description
          importance: Importance.high,
        );

        // Android 채널 생성
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        await androidPlugin?.createNotificationChannel(channel);

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
            print('알림 응답 처리: ${response.payload}');
          },
        );

        // 테스트 알림 표시 (권한이 허용되었는지 확인하기 위해)
        if (status.isGranted) {
          print('테스트 알림 표시 시도...');
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
        }

        // 상태 업데이트
        state = state.copyWith(
          notificationPermissionStatus: AsyncData(status.isGranted),
        );
      }
    } catch (e, st) {
      print('알림 권한 요청 중 오류 발생: $e');
      print('스택 트레이스: $st');
      state = state.copyWith(notificationPermissionStatus: AsyncError(e, st));
    }
  }

  Future<void> _handleRequestLocationPermission() async {
    try {
      print('위치 권한 요청 시작...');
      state = state.copyWith(locationPermissionStatus: const AsyncLoading());

      if (Platform.isIOS) {
        print('iOS 위치 권한 요청 중...');

        // 먼저 권한 상태 확인
        final status = await Permission.location.status;
        print('iOS 현재 위치 권한 상태: $status');

        if (status.isPermanentlyDenied) {
          // 사용자가 이전에 "허용 안 함"을 선택한 경우
          print('iOS 위치 권한이 영구적으로 거부됨 - 설정에서 변경 필요');
          state = state.copyWith(
            locationPermissionStatus: const AsyncData(false),
          );
          return;
        }

        // Geolocator 패키지를 사용하여 iOS 위치 권한 요청
        LocationPermission permission = await Geolocator.requestPermission();

        bool isGranted =
            permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;

        print('iOS 위치 권한 요청 결과: $isGranted (permission: $permission)');
        state = state.copyWith(locationPermissionStatus: AsyncData(isGranted));
      } else {
        print('Android 위치 권한 요청 중...');

        // 먼저 Permission.location을 요청하고
        final status = await Permission.location.request();
        print('Android 위치 권한 요청 결과: ${status.isGranted}');

        // Geolocator로 권한 요청 (더 강력한 결과를 위해)
        LocationPermission permission = await Geolocator.requestPermission();

        bool isGranted =
            permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;

        print('Android 위치 권한 요청 결과: $isGranted (permission: $permission)');

        // 위치 서비스가 활성화되어 있는지 확인 (옵션)
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          print('위치 서비스가 비활성화되어 있습니다.');
          // 위치 서비스 켜기 요청하는 로직 추가 가능
        }

        state = state.copyWith(locationPermissionStatus: AsyncData(isGranted));
      }
    } catch (e, st) {
      print('위치 권한 요청 중 오류 발생: $e');
      print('스택 트레이스: $st');
      state = state.copyWith(locationPermissionStatus: AsyncError(e, st));
    }
  }

  Future<void> _handleCompleteOnboarding() async {
    try {
      state = state.copyWith(onboardingCompletedStatus: const AsyncLoading());

      // 온보딩 완료 상태 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedOnboarding', true);

      state = state.copyWith(onboardingCompletedStatus: const AsyncData(true));
    } catch (e, st) {
      state = state.copyWith(onboardingCompletedStatus: AsyncError(e, st));
    }
  }

  Future<void> _checkPermissions() async {
    try {
      print('권한 상태 확인 중...');
      state = state.copyWith(
        notificationPermissionStatus: const AsyncLoading(),
        locationPermissionStatus: const AsyncLoading(),
      );

      // 알림 권한 확인
      bool notificationGranted = false;
      if (Platform.isIOS) {
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
        notificationGranted = settings?.didNotificationLaunchApp ?? false;
      } else {
        final notificationStatus = await Permission.notification.status;
        notificationGranted = notificationStatus.isGranted;
      }

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

      print('알림 권한 상태: $notificationGranted');
      print('위치 권한 상태: $locationGranted');

      state = state.copyWith(
        notificationPermissionStatus: AsyncData(notificationGranted),
        locationPermissionStatus: AsyncData(locationGranted),
      );
    } catch (e, st) {
      print('권한 상태 확인 중 오류 발생: $e');
      print('스택 트레이스: $st');
      state = state.copyWith(
        notificationPermissionStatus: AsyncError(e, st),
        locationPermissionStatus: AsyncError(e, st),
      );
    }
  }
}
