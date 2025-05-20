// lib/onboarding/presentation/onboarding_notifier.dart
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
  }

  void _handlePreviousPage() {
    if (state.currentPage > 0) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  void _handleGoToPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  Future<void> _handleRequestNotificationPermission() async {
    try {
      state = state.copyWith(
        notificationPermissionStatus: const AsyncLoading(),
      );

      final status = await Permission.notification.request();

      state = state.copyWith(
        notificationPermissionStatus: AsyncData(status.isGranted),
      );
    } catch (e, st) {
      state = state.copyWith(notificationPermissionStatus: AsyncError(e, st));
    }
  }

  Future<void> _handleRequestLocationPermission() async {
    try {
      state = state.copyWith(locationPermissionStatus: const AsyncLoading());

      final status = await Permission.location.request();

      state = state.copyWith(
        locationPermissionStatus: AsyncData(status.isGranted),
      );
    } catch (e, st) {
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
      state = state.copyWith(
        notificationPermissionStatus: const AsyncLoading(),
        locationPermissionStatus: const AsyncLoading(),
      );

      final notificationStatus = await Permission.notification.status;
      final locationStatus = await Permission.location.status;

      state = state.copyWith(
        notificationPermissionStatus: AsyncData(notificationStatus.isGranted),
        locationPermissionStatus: AsyncData(locationStatus.isGranted),
      );
    } catch (e, st) {
      state = state.copyWith(
        notificationPermissionStatus: AsyncError(e, st),
        locationPermissionStatus: AsyncError(e, st),
      );
    }
  }
}
