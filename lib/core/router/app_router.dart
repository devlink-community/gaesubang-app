// lib/core/router/app_router.dart
import 'package:devlink_mobile_app/app_setting/presentation/open_source_license_screen_root.dart';
import 'package:devlink_mobile_app/app_setting/presentation/settings_screen_root.dart';
import 'package:devlink_mobile_app/auth/presentation/forgot_password/forgot_password_screen_root.dart';
import 'package:devlink_mobile_app/auth/presentation/login/login_screen_root.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_screen_root.dart';
import 'package:devlink_mobile_app/auth/presentation/terms/terms_screen_root.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_screen_root.dart';
import 'package:devlink_mobile_app/community/presentation/community_list/community_list_screen_root.dart';
import 'package:devlink_mobile_app/community/presentation/community_search/community_search_screen_root.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_screen_root.dart';
import 'package:devlink_mobile_app/core/component/navigation_bar.dart';
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
import 'package:devlink_mobile_app/profile/presentation/profile_edit/mock_profile_edit_screen.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_edit/profile_edit_screen_root.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_screen_root.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app_setting/presentation/forgot_password_screen_root_2.dart';

part 'app_router.g.dart';

// 개발용 강제 로그인 상태를 관리하는 Provider
@riverpod
class DevLoginState extends _$DevLoginState {
  @override
  bool build() => false; // true로 설정하여 개발용 강제 로그인 상태로 시작

  void toggle() => state = !state;
  void enable() => state = true;
  void disable() => state = false;
}

// GoRouter Provider
@riverpod
GoRouter appRouter(Ref ref) {
  // 개발용 강제 로그인 상태 구독
  final devLogin = ref.watch(devLoginStateProvider);

  return GoRouter(
    initialLocation: devLogin ? '/home' : '/login',
    redirect: (context, state) {
      // 루트 경로('/')에 대한 처리 추가
      if (state.uri.path == '/') {
        return devLogin ? '/home' : '/login';
      }

      // 현재 경로
      final currentPath = state.uri.path;

      // 로그인이 필요하지 않은 경로 목록
      final publicPaths = ['/login', '/sign-up', '/terms', '/forget-password'];

      // 개발용 강제 로그인 모드가 활성화된 경우
      if (devLogin) {
        // 로그인 화면으로 가려는 경우 홈으로 리다이렉트
        if (publicPaths.any(currentPath.startsWith)) {
          return '/home';
        }
      }

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

      // === 네비게이션 바 있는 메인 쉘 라우트 (메인 탭 화면들만 포함) ===
      ShellRoute(
        builder: (context, state, child) {
          // 프로필 이미지
          final userStorage = UserStorage.instance;
          final currentUser = userStorage.currentUser;
          String? profileImageUrl;

          if (currentUser != null) {
            final profile = userStorage.getProfileById(currentUser.id!);
            profileImageUrl = profile?.image;
          } else {
            final defaultUser = userStorage.getUserByEmail('test1@example.com');
            if (defaultUser != null) {
              final profile = userStorage.getProfileById(defaultUser.id!);
              profileImageUrl = profile?.image;
            }
          }

          // 현재 활성화된 탭 인덱스 계산
          int currentIndex = 0; // 기본값 홈
          final String path = state.uri.path;

          if (path == '/community') {
            currentIndex = 1;
          } else if (path == '/group') {
            currentIndex = 3; // 그룹을 인덱스 3으로 변경
          } else if (path == '/profile') {
            currentIndex = 4;
          }

          return Scaffold(
            body: child,
            bottomNavigationBar: AppBottomNavigationBar(
              currentIndex: currentIndex,
              profileImageUrl: profileImageUrl,
              onTap: (index) {
                switch (index) {
                  case 0:
                    context.go('/home');
                    break;
                  case 1:
                    context.go('/community');
                    break;
                  case 2:
                    // 가운데 버튼은 드롭다운 메뉴를 표시
                    break;
                  case 3:
                    context.go('/group');
                    break;
                  case 4:
                    context.go('/profile');
                    break;
                }
              },
              onCreatePost: () {
                // 게시글 작성 화면으로 이동
                context.push('/community/write');
              },
              onCreateGroup: () {
                // 그룹 생성 화면으로 이동
                context.push('/group/create');
              },
            ),
          );
        },
        routes: [
          // === 홈 탭 ===
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreenRoot(),
          ),
          // === 커뮤니티 목록 탭 ===
          GoRoute(
            path: '/community',
            builder: (context, state) => const CommunityListScreenRoot(),
          ),
          // === 그룹 목록 탭 ===
          GoRoute(
            path: '/group',
            builder: (context, state) => const GroupListScreenRoot(),
          ),
          // === 프로필 탭 ===
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreenRoot(),
          ),
        ],
      ),

      // === 쉘 밖에 있는 페이지들 (바텀 네비게이션 바 없음) ===

      // --- 커뮤니티 관련 디테일/액션 페이지들 ---
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

      // --- 그룹 관련 디테일/액션 페이지들 ---
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
        path: '/forgot-password-2',
        builder: (context, state) => const ForgotPasswordScreenRoot2(),
      ),
      GoRoute(
        path: '/profile-edit-demo',
        builder: (context, state) => const MockProfileEditScreen(),
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
          body: Center(child: Text('요청한 경로 "${state.uri.path}"를 찾을 수 없습니다')),
        ),
  );
}
