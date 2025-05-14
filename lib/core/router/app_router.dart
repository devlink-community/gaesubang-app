// lib/core/router/app_router.dart
import 'package:devlink_mobile_app/auth/presentation/forgot_password/forgot_password_screen_root.dart';
import 'package:devlink_mobile_app/auth/presentation/login/login_screen_root.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_screen_root.dart';
import 'package:devlink_mobile_app/auth/presentation/terms/terms_screen_root.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_screen_root.dart';
import 'package:devlink_mobile_app/community/presentation/community_list/community_list_screen_root.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_screen_root.dart';
import 'package:devlink_mobile_app/core/component/navigation_bar.dart';
import 'package:devlink_mobile_app/edit_intro/presentation/screens/edit_intro_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_create/group_create_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_search/group_search_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/group_timer_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/mock_screen/mock_screen.dart';
import 'package:devlink_mobile_app/intro/presentation/intro_screen_root.dart';
import 'package:devlink_mobile_app/notification/presentation/notification_screen.root.dart';
import 'package:devlink_mobile_app/setting/presentation/settings_screen_root.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  // 로그인 상태 감지를 위한 Provider는 필요 시 추가
  // final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/', // 기본 경로는 홈으로 리다이렉트됨
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

      // === 기본 경로 -> 홈으로 리다이렉트 ===
      GoRoute(path: '/', redirect: (_, __) => '/home'),

      // === 메인 탭 화면 (홈, 커뮤니티, 그룹, 알림, 프로필) ===
      ShellRoute(
        builder: (context, state, child) {
          // 현재 활성화된 탭 인덱스 계산
          int currentIndex = 0; // 기본값 홈
          final String path = state.uri.path;

          if (path.startsWith('/community')) {
            currentIndex = 1;
          } else if (path.startsWith('/group')) {
            currentIndex = 2;
          } else if (path.startsWith('/notifications')) {
            currentIndex = 3;
          } else if (path.startsWith('/profile')) {
            currentIndex = 4;
          }

          // 프로필 이미지 URL (로그인된 사용자에서 가져올 수 있음)
          String? profileImageUrl;
          // 유저 상태 활성화 시 아래 코드 사용
          // final user = ref.watch(userProfileProvider).valueOrNull;
          // profileImageUrl = user?.profileImageUrl;

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
                    context.go('/group');
                    break;
                  case 3:
                    context.go('/notifications');
                    break;
                  case 4:
                    context.go('/profile');
                    break;
                }
              },
            ),
          );
        },
        routes: [
          // === 홈 탭 ===
          GoRoute(
            path: '/home',
            builder: (context, state) => const _HomeMockScreen(),
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
            builder: (context, state) => const IntroScreenRoot(),
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

/// Mock 스크린들
class _HomeMockScreen extends StatelessWidget {
  const _HomeMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('🏠 Home Screen (Mock)')));
  }
}
