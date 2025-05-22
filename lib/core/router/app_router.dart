// lib/core/router/app_router.dart
import 'package:devlink_mobile_app/app_setting/presentation/open_source_license_screen_root.dart';
import 'package:devlink_mobile_app/app_setting/presentation/settings_screen_root.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/auth/presentation/forgot_password/forgot_password_screen_root.dart';
import 'package:devlink_mobile_app/auth/presentation/login/login_screen_root.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_screen_root.dart';
import 'package:devlink_mobile_app/auth/presentation/terms/terms_screen_root.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_screen_root.dart';
import 'package:devlink_mobile_app/community/presentation/community_list/community_list_screen_root.dart';
import 'package:devlink_mobile_app/community/presentation/community_search/community_search_screen_root.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_screen_root.dart';
import 'package:devlink_mobile_app/core/auth/auth_state.dart';
import 'package:devlink_mobile_app/core/layout/main_shell.dart';
import 'package:devlink_mobile_app/core/utils/stream_listenable.dart';
import 'package:devlink_mobile_app/group/presentation/group_attendance/attendance_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_chat/group_chat_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_create/group_create_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_detail/group_detail_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_detail/mock_screen/mock_screen.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_search/group_search_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_screen_root.dart';
import 'package:devlink_mobile_app/home/presentation/home_screen_root.dart';
import 'package:devlink_mobile_app/map/presentation/group_map_screen_root.dart';
import 'package:devlink_mobile_app/notification/presentation/notification_screen_root.dart';
import 'package:devlink_mobile_app/onboarding/module.dart/onboarding_completion_status.dart';
import 'package:devlink_mobile_app/onboarding/presentation/onboarding_screen_root.dart';
import 'package:devlink_mobile_app/onboarding/presentation/splash_screen_root.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_edit/profile_edit_screen_root.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_screen_root.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app_setting/presentation/change_password_root.dart';

part 'app_router.g.dart';

// 라우터 상태 유지를 위한 StatefulNavigationShell 클래스
class OnboardingShell extends StatefulWidget {
  final Widget child;

  const OnboardingShell({super.key, required this.child});

  @override
  State<OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends State<OnboardingShell> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// GoRouter Provider
@riverpod
GoRouter appRouter(Ref ref) {
  // 인증 상태 스트림을 Listenable로 변환
  final authRepo = ref.watch(authRepositoryProvider);
  final authStateListenable = StreamListenable(authRepo.authStateChanges);

  // 온보딩 상태 구독
  final onboardingCompleted = ref.watch(onboardingCompletionStatusProvider);

  if (kDebugMode) {
    print('appRouter 재계산: onboardingCompleted=$onboardingCompleted');
  }

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    // 디버그 모드에서 라우팅 정보 출력
    refreshListenable: authStateListenable,
    // 인증 상태 변경만 감시
    routes: [
      // === 스플래시 라우트 ===
      GoRoute(path: '/', builder: (context, state) => const SplashScreenRoot()),

      // === 온보딩 라우트 (ShellRoute로 감싸기) ===
      ShellRoute(
        builder: (context, state, child) {
          // OnboardingShell로 감싸서 상태 유지
          return OnboardingShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const OnboardingScreenRoot(),
          ),
        ],
      ),

      // === 스플래시 라우트 유지 ===
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreenRoot(),
      ),

      // === 인증 관련 라우트 (로그인 필요 없음) ===
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreenRoot(),
      ),
      GoRoute(
        path: '/forget-password',
        builder: (context, state) => const ForgotPasswordScreenRoot(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) {
          final termsId = state.extra as String?;
          return SignupScreenRoot(agreedTermsId: termsId);
        },
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsScreenRoot(),
      ),

      // === 네비게이션 바 있는 메인 쉘 라우트 ===
      ShellRoute(
        builder: (context, state, child) {
          // MainShell 위젯 사용으로 변경
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreenRoot(),
          ),
          GoRoute(
            path: '/community',
            builder: (context, state) => const CommunityListScreenRoot(),
          ),
          GoRoute(
            path: '/group',
            builder: (context, state) => const GroupListScreenRoot(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreenRoot(),
          ),
        ],
      ),

      // === 쉘 밖에 있는 페이지들 ===
      GoRoute(
        path: '/community/write',
        builder: (context, state) => const CommunityWriteScreenRoot(),
      ),
      GoRoute(
        path: '/community/search',
        builder: (context, state) => const CommunitySearchScreenRoot(),
      ),
      GoRoute(
        path: '/community/:id',
        builder:
            (context, state) =>
                CommunityDetailScreenRoot(postId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/group/create',
        builder: (context, state) => const GroupCreateScreenRoot(),
      ),
      GoRoute(
        path: '/group/search',
        builder: (context, state) => const GroupSearchScreenRoot(),
      ),
      GoRoute(
        path: '/group/:id',
        builder:
            (context, state) =>
                GroupDetailScreenRoot(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/group/:id/map',
        builder:
            (context, state) =>
                GroupMapScreenRoot(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/group/:id/attendance',
        builder:
            (context, state) =>
                AttendanceScreenRoot(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/group/:id/settings',
        builder:
            (context, state) =>
                GroupSettingsScreenRoot(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/group/:id/chat',
        builder:
            (context, state) =>
                GroupChatScreenRoot(groupId: state.pathParameters['id']!),
      ),

      // --- 기타 페이지들 ---
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreenRoot(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreenRoot(),
      ),
      GoRoute(
        path: '/open-source-licenses',
        builder: (context, state) => const OpenSourceLicenseScreenRoot(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const ProfileEditScreenRoot(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreenRoot(),
      ),
      GoRoute(
        path: '/user/:id/profile',
        builder:
            (context, state) =>
                MockUserProfileScreen(userId: state.pathParameters['id']!),
      ),
    ],
    redirect: (context, state) {
      // 현재 경로 및 인증 상태
      final currentPath = state.matchedLocation;

      // StreamListenable에서 인증 상태 확인
      final authState = authStateListenable.currentValue;
      final isAuthenticated =
          authState is AuthState && authState.isAuthenticated;

      // 디버깅용 정보 출력(개발자 모드에서만)
      if (kDebugMode) {
        print('Router.redirect: 현재 경로 - $currentPath');
        print('onboardingCompleted: $onboardingCompleted');
        print('isAuthenticated: $isAuthenticated');
      }

      // 1. 루트 경로('/')는 앱 시작시 스플래시를 위해 유지
      if (currentPath == '/') {
        return null;
      }

      // 2. '/splash' 경로로의 직접 접근은 적절한 화면으로 리다이렉션
      if (currentPath == '/splash') {
        if (!onboardingCompleted) {
          return '/onboarding';
        } else {
          return isAuthenticated ? '/home' : '/login';
        }
      }

      // 3. 온보딩 경로는 항상 유지 (중요: 이 부분이 핵심)
      if (currentPath == '/onboarding') {
        return null;
      }

      // 인증이 필요하지 않은 경로 목록
      final publicPaths = [
        '/login',
        '/sign-up',
        '/terms',
        '/forget-password',
      ];

      // 현재 경로가 퍼블릭 경로인지 확인
      final isPublicPath = publicPaths.any(
        (path) => currentPath == path || currentPath.startsWith(path),
      );

      // 4. 온보딩 미완료 사용자는 온보딩으로 리디렉션 (퍼블릭 경로는 제외)
      if (!onboardingCompleted && !isPublicPath) {
        if (kDebugMode) {
          print('Router: 온보딩 미완료 사용자 리다이렉트 - $currentPath → /onboarding');
        }
        return '/onboarding';
      }

      // 5. 비인증 사용자는 퍼블릭 경로 외에는 로그인으로 리디렉션
      if (!isAuthenticated && !isPublicPath) {
        if (kDebugMode) {
          print('Router: 비인증 사용자가 인증 필요 페이지 접근 시도 - $currentPath');
        }
        return '/login';
      }

      // 6. 인증된 사용자가 로그인/회원가입 페이지 접근 시 홈으로 리디렉션
      if (isAuthenticated && isPublicPath) {
        if (kDebugMode) {
          print('Router: 인증된 사용자가 인증 페이지 접근 시도 - $currentPath');
        }
        return '/home';
      }

      // 기타 경로는 그대로 유지
      return null;
    },

    // === 에러 페이지 처리 ===
    errorBuilder:
        (context, state) => Scaffold(
          appBar: AppBar(title: const Text('페이지를 찾을 수 없습니다')),
          body: Center(
            child: Text('요청한 경로 "${state.matchedLocation}"를 찾을 수 없습니다'),
          ),
        ),
  );
}
