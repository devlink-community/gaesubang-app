// lib/onboarding/presentation/onboarding_action.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_action.freezed.dart';

@freezed
sealed class OnboardingAction with _$OnboardingAction {
  const factory OnboardingAction.nextPage() = NextPage; // 다음 페이지
  const factory OnboardingAction.previousPage() = PreviousPage; // 이전페이지
  const factory OnboardingAction.goToPage(int page) = GoToPage; // 특정 페이지로 가기
  const factory OnboardingAction.requestNotificationPermission() =
      RequestNotificationPermission; // 알림 권한 요청
  const factory OnboardingAction.requestLocationPermission() =
      RequestLocationPermission; // 위치 권한 요청
  const factory OnboardingAction.completeOnboarding() =
      CompleteOnboarding; // 온보딩 완료 여부
  const factory OnboardingAction.checkPermissions() = CheckPermissions; // 권한 체크
}
