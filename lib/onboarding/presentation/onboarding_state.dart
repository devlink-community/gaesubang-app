// lib/onboarding/presentation/onboarding_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'onboarding_state.freezed.dart';

@freezed
class OnboardingState with _$OnboardingState {
  const OnboardingState({
    this.currentPage = 0,
    this.notificationPermissionStatus = const AsyncLoading(),
    this.locationPermissionStatus = const AsyncLoading(),
    this.onboardingCompletedStatus = const AsyncLoading(),
  });

  final int currentPage;
  final AsyncValue<bool> notificationPermissionStatus;
  final AsyncValue<bool> locationPermissionStatus;
  final AsyncValue<bool> onboardingCompletedStatus;
}
