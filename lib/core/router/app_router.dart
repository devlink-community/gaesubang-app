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
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app_setting/presentation/forgot_password_screen_root_2.dart';
import '../auth/auth_provider.dart';

part 'app_router.g.dart';

// GoRouter Provider
@riverpod
GoRouter appRouter(Ref ref) {
  // 인증 상태 스트림을 직접 가져와서 Listenable로 변환
  final authRepo = ref.watch(authRepositoryProvider);
  final refreshListenable = StreamListenable(authRepo.authStateChanges);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshListenable, // 인증 상태 변화 감지
    redirect: (context, state) {
      // 루트 경로('/')에 대한 처리
      if (state.matchedLocation == '/') {
        return '/login';
      }

      // 인증 상태 확인 - switch 패턴 매칭 사용
      final authStateAsync = ref.read(authStateProvider);

      return switch (authStateAsync) {
        AsyncData(:final value) => () {
          final isLoggedIn = value.isAuthenticated;
          final currentPath = state.matchedLocation;

          // 로그인이 필요하지 않은 경로 목록
          final publicPaths = [
            '/login',
            '/sign-up',
            '/terms',
            '/forget-password',
          ];

          // 인증이 필요한 페이지에 비로그인 상태로 접근
          if (!isLoggedIn && !publicPaths.any(currentPath.startsWith)) {
            return '/login';
          }

          // 이미 로그인된 상태에서 인증 페이지 접근
          if (isLoggedIn && publicPaths.any(currentPath.startsWith)) {
            return '/home';
          }

          return null;
        }(),
        AsyncLoading() => null, // 로딩 중이면 현재 위치 유지
        AsyncError() => '/login', // 에러 시 로그인 페이지로
        _ => null, // 기본값 (다른 모든 경우)
      };
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
