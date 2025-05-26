// lib/onboarding/module/onboarding_completion_status.dart
import 'package:devlink_mobile_app/onboarding/presentation/onboarding_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_completion_status.g.dart';

// 더 명확한 이름으로 변경
@riverpod
// ignore: deprecated_member_use_from_same_package
bool onboardingCompletionStatus(OnboardingCompletionStatusRef ref) {
  final status = ref.watch(
    onboardingNotifierProvider.select(
      (state) => state.onboardingCompletedStatus,
    ),
  );

  return status.maybeWhen(data: (completed) => completed, orElse: () => false);
}
