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
import 'package:devlink_mobile_app/core/layout/main_shell.dart'; // MainShell 추가
import 'package:devlink_mobile_app/core/utils/stream_listenable.dart';
import 'package:devlink_mobile_app/group/presentation/group_attendance/attendance_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_create/group_create_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_detail/group_detail_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_detail/mock_screen/mock_screen.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_search/group_search_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_screen_root.dart';
import 'package:devlink_mobile_app/home/presentation/home_screen_root.dart';
import 'package:devlink_mobile_app/map/presentation/map_screen_root.dart';
import 'package:devlink_mobile_app/notification/presentation/notification_screen_root.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_edit/profile_edit_screen_root.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_screen_root.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app_setting/presentation/forgot_password_screen_root_2.dart';

part 'app_router.g.dart';

// GoRouter Provider
@riverpod
GoRouter appRouter(Ref ref) {
  // 인증 상태 스트림을 직접 가져와서 Listenable로 변환
  // ✅ 개선된 AuthStateListenable 사용
  final authRepo = ref.watch(authRepositoryProvider);
  final authStateListenable = AuthStateListenable(authRepo.authStateChanges);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authStateListenable, // 인증 상태 변화 감지
    redirect: (context, state) {
      // 디버깅용 정보 출력 (개발 모드에서만)
      if (kDebugMode) {
        authStateListenable.printDebugInfo();
      }

      // 루트 경로('/')에 대한 처리
      if (state.matchedLocation == '/') {
        return '/login';
      }

      // ✅ 최적화: 캐시된 인증 상태 사용
      final isAuthenticated = authStateListenable.isAuthenticated;
      final isLoading = authStateListenable.isLoading;
      final currentPath = state.matchedLocation;

      // 로딩 중일 때는 리다이렉트하지 않음 (깜빡임 방지)
      if (isLoading) {
        return null;
      }

      // 인증이 필요하지 않은 경로 목록
      final publicPaths = ['/login', '/sign-up', '/terms', '/forget-password'];

      final isPublicPath = publicPaths.any(currentPath.startsWith);

      // 인증이 필요한 페이지에 비로그인 상태로 접근
      if (!isAuthenticated && !isPublicPath) {
        if (kDebugMode) {
          print('Router: 비인증 사용자가 인증 필요 페이지 접근 시도 - $currentPath');
        }
        return '/login';
      }

      // 이미 로그인된 상태에서 인증 페이지 접근
      if (isAuthenticated && isPublicPath) {
        if (kDebugMode) {
          print('Router: 인증된 사용자가 인증 페이지 접근 시도 - $currentPath');
        }
        return '/home';
      }

      // GoRouter의 refreshListenable이 인증 상태 변화를 자동으로 감지하여
      // 적절한 리다이렉트를 수행하므로 여기서는 null 반환
      return null;
    },
    routes: [
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
                MapScreenRoot(groupId: state.pathParameters['id']!),
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
        path: '/forgot-password-2',
        builder: (context, state) => const ForgotPasswordScreenRoot2(),
      ),
      GoRoute(
        path: '/user/:id/profile',
        builder:
            (context, state) =>
                MockUserProfileScreen(userId: state.pathParameters['id']!),
      ),
    ],

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
