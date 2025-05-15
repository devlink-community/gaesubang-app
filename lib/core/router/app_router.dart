// lib/core/router/app_router.dart
import 'package:devlink_mobile_app/auth/presentation/forgot_password/forgot_password_screen_root.dart';
import 'package:devlink_mobile_app/auth/presentation/login/login_screen_root.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_screen_root.dart';
import 'package:devlink_mobile_app/auth/presentation/terms/terms_screen_root.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_screen_root.dart';
import 'package:devlink_mobile_app/community/presentation/community_list/community_list_screen_root.dart';
import 'package:devlink_mobile_app/community/presentation/community_search/community_search_screen_root.dart'; // 추가
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_screen_root.dart';
import 'package:devlink_mobile_app/core/component/navigation_bar.dart';
import 'package:devlink_mobile_app/edit_intro/presentation/screens/edit_intro_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_create/group_create_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_search/group_search_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/group_timer_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/mock_screen/mock_screen.dart';
import 'package:devlink_mobile_app/home/presentation/home_screen_root.dart';
import 'package:devlink_mobile_app/intro/presentation/intro_screen_root.dart';
import 'package:devlink_mobile_app/notification/presentation/notification_screen_root.dart';
import 'package:devlink_mobile_app/setting/presentation/settings_screen_root.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/data/data_source/user_storage.dart';
import '../../edit_intro/presentation/screens/edit_intro_demo_screen.dart';
import '../../setting/presentation/forgot_password_screen_root_2.dart';

part 'app_router.g.dart';

// 개발용 강제 로그인 상태를 관리하는 Provider
@riverpod
class DevLoginState extends _$DevLoginState {
  @override
  bool build() => false; // true로 설정하여 개발용 강제 로그인 상태로 시작 (false이면 로그인 로직대로 동작)

  void toggle() => state = !state;

  void enable() => state = true;

  void disable() => state = false;
}

// GoRouter Provider
@riverpod
GoRouter appRouter(ref) {
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

        // 다른 화면은 정상 이동
        return null;
      }

      // 일반 모드에서는 임시로 모든 페이지 이동 허용
      // 추후 실제 로그인 상태에 따른 리다이렉트 로직 구현 예정
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

      // === 메인 탭 화면 (홈, 커뮤니티, 그룹, 알림, 프로필) ===
      // ShellRoute 부분 수정
      ShellRoute(
        builder: (context, state, child) {
          // 현재 활성화된 탭 인덱스 계산
          int currentIndex = 0; // 기본값 홈
          final String path = state.uri.path;

          if (path.startsWith('/community')) {
            currentIndex = 1;
          } else if (path.startsWith('/group')) {
            currentIndex = 3; // 그룹을 인덱스 3으로 변경
          } else if (path.startsWith('/profile')) {
            currentIndex = 4;
          }

          // 프로필 이미지는 더 이상 외부 URL을 사용하지 않음
          // 실제 사용자 프로필 구현 시 사용자 데이터에서 가져오도록 수정
          final userStorage = UserStorage.instance;
          final currentUser = userStorage.currentUser;
          String? profileImageUrl;

          if (currentUser != null) {
            // 현재 로그인된 사용자의 프로필 이미지 가져오기
            final profile = userStorage.getProfileById(currentUser.id!);
            profileImageUrl = profile?.image;
          } else {
            // 개발 모드에서 첫 번째 사용자의 이미지 사용
            final defaultUser = userStorage.getUserByEmail('test1@example.com');
            if (defaultUser != null) {
              final profile = userStorage.getProfileById(defaultUser.id!);
              profileImageUrl = profile?.image;
            }
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
                    // 가운데 버튼은 드롭다운 메뉴를 표시하므로 탭 이동 처리하지 않음
                    break;
                  case 3:
                    context.go('/group'); // 그룹 탭으로 이동
                    break;
                  case 4:
                    context.go('/profile');
                    break;
                }
              },
              // 드롭다운 메뉴의 액션 핸들러
              onCreatePost: () {
                context.push('/community/write');
              },
              onCreateGroup: () {
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
            // 추후 실제 홈 화면으로 대체
          ),

          // === 커뮤니티 탭 ===
          GoRoute(
            path: '/community',
            builder: (context, state) => const CommunityListScreenRoot(),
            routes: [
              // 커뮤니티 글 작성
              GoRoute(
                path: 'write',
                builder: (context, state) => const CommunityWriteScreenRoot(),
              ),
              // 커뮤니티 검색 화면 (추가)
              GoRoute(
                path: 'search',
                builder: (context, state) => const CommunitySearchScreenRoot(),
              ),
              // 커뮤니티 상세 페이지
              GoRoute(
                path: ':id',
                builder:
                    (context, state) => CommunityDetailScreenRoot(
                      postId: state.pathParameters['id']!,
                    ),
              ),
            ],
          ),

          // === 그룹 탭 ===
          GoRoute(
            path: '/group',
            builder: (context, state) => const GroupListScreenRoot(),
            routes: [
              // 그룹 생성
              GoRoute(
                path: 'create',
                builder: (context, state) => const GroupCreateScreenRoot(),
              ),
              // 그룹 검색
              GoRoute(
                path: 'search',
                builder: (context, state) => const GroupSearchScreenRoot(),
              ),
              // 그룹 상세
              GoRoute(
                path: ':id',
                builder:
                    (context, state) => GroupTimerScreenRoot(
                      groupId: state.pathParameters['id']!,
                    ),
              ),
              // 그룹 출석
              GoRoute(
                path: ':id/attendance',
                builder:
                    (context, state) => MockGroupAttendanceScreen(
                      groupId: state.pathParameters['id']!,
                    ),
              ),
              // 그룹 설정
              GoRoute(
                path: ':id/settings',
                builder:
                    (context, state) => GroupSettingsScreenRoot(
                      groupId: state.pathParameters['id']!,
                    ),
              ),
            ],
          ),

          // === 알림 탭 ===
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationScreenRoot(),
          ),

          // === 프로필 탭 ===
          GoRoute(
            path: '/profile',
            builder: (context, state) {
              // 강제로 새로 생성하여 항상 최신 데이터를 로드하도록 함
              return const IntroScreenRoot();
            },
          ),
        ],
      ),

      // === 프로필 관련 독립 라우트 ===
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreenRoot(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditIntroRoot(),
      ),
      GoRoute(
        path: '/forgot-password-2',
        builder: (context, state) => const ForgotPasswordScreenRoot2(),
      ),
      // demo router
      GoRoute(
        path: '/profile-edit-demo',
        builder: (context, state) => const ProfileEditDemoScreen(),
      ),

      // === 유저 프로필 보기 (그룹에서 사용) ===
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
