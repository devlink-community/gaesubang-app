// lib/onboarding/presentation/onboarding_screen_root.dart
import 'package:devlink_mobile_app/onboarding/domain/model/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/onboarding/presentation/onboarding_notifier.dart';
import 'package:devlink_mobile_app/onboarding/presentation/onboarding_screen.dart';

class OnboardingScreenRoot extends ConsumerWidget {
  const OnboardingScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.watch(onboardingNotifierProvider.notifier);

    // 온보딩 완료 상태 감지
    final onboardingCompleted = state.onboardingCompletedStatus.maybeWhen(
      data: (completed) => completed,
      orElse: () => false,
    );

    // 이미 완료된 경우만 홈으로 이동, 직접 상태 변경시에만 작동
    if (onboardingCompleted) {
      // 다음 프레임에서 이동 (빌드 중 네비게이션 방지)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pushReplacement('/login'); // 또는 '/home'
      });
    }

    // 온보딩 페이지 목록 구성
    final List<OnboardingPageModel> pages = [
      // 앱 소개 페이지
      OnboardingPageModel(
        title: '개수방에 오신 것을\n 환영합니다',
        description: '개발자들이 함께 성장하는 공간,\n집중하고 성장하는 시간을 만들어 보세요.',
        icon: Icons.timer,
        backgroundColor: AppColorStyles.primary100,
      ),
      // 알림 권한 페이지
      OnboardingPageModel(
        title: '알림 설정',
        description: '타이머 종료 및 그룹 활동 알림을 받으세요.\n중요한 순간을 놓치지 않게 도와드립니다.',
        icon: Icons.notifications_active,
        backgroundColor: AppColorStyles.secondary01,
        actionButtonText: '알림 권한 허용하기',
      ),
      // 위치 권한 페이지
      OnboardingPageModel(
        title: '위치 권한',
        description: '주변 스터디 모임을 찾고\n내 위치 기반으로 그룹을 검색해 보세요.',
        icon: Icons.location_on,
        backgroundColor: AppColorStyles.primary80,
        actionButtonText: '위치 권한 허용하기',
      ),
      // 마지막 페이지
      OnboardingPageModel(
        title: '모든 준비가\n 완료되었습니다!',
        description: '이제 개수방과 함께\n개발 공부를 시작해볼까요?',
        icon: Icons.check_circle,
        backgroundColor: const Color(0xFF4CAF50), // 성공 색상
      ),
    ];

    return OnboardingScreen(
      pages: pages,
      state: state,
      onAction: notifier.onAction,
    );
  }
}
