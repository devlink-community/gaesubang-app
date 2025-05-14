// lib/core/route/app_router.dart
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/community/module/community_router.dart';
import 'package:devlink_mobile_app/group/module/group_di.dart';
import 'package:devlink_mobile_app/intro/module/intro_route.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../community/presentation/community_list/community_list_screen_root.dart';
import '../../group/presentation/group_list/group_list_screen_root.dart';
import '../../intro/presentation/intro_screen_root.dart';
import '../component/navigation_bar.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // 로그인 및 인증 관련 라우트
      ...authRoutes,

      // 기본 경로 -> 홈으로 리다이렉트
      GoRoute(path: '/', redirect: (_, __) => '/home'),

      // 메인 탭 화면 (홈, 그룹, 커뮤니티, 알림, 프로필)
      ShellRoute(
        builder: (context, state, child) {
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

          // 프로필 이미지 URL - 상태관리로부터 가져와야 함
          String? profileImageUrl; // 실제 구현에서는 상태에서 가져와야 함

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
          // 홈 탭
          GoRoute(
            path: '/home',
            builder: (context, state) => const _HomeMockScreen(),
          ),

          // 그룹 탭
          GoRoute(
            path: '/group',
            builder: (context, state) => const GroupListScreenRoot(),
          ),

          // 커뮤니티 탭
          GoRoute(
            path: '/community',
            builder: (context, state) => const CommunityListScreenRoot(),
          ),

          // 알림 탭
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const _NotificationsMockScreen(),
          ),

          // 프로필 탭 - 경로를 /profile로 수정
          GoRoute(
            path: '/profile',
            builder: (context, state) => const IntroScreenRoot(),
          ),
        ],
      ),

      ...introRoutes,
      ...communityRoutes,
      ...groupRoutes,
    ],

    // 에러 페이지 처리
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

class _NotificationsMockScreen extends StatelessWidget {
  const _NotificationsMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('🔔 알림 (Mock)')));
  }
}
