// lib/core/layout/main_shell.dart
import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../component/nav_bar/navigation_bar.dart';

/// 메인 레이아웃을 관리하는 Shell 위젯
/// 하단 네비게이션 바와 콘텐츠 영역을 포함
class MainShell extends ConsumerWidget {
  /// 자식 위젯 (라우터에서 전달된 현재 화면)
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    AppLogger.debug(
      '현재 사용자 감지: ${currentUser?.nickname ?? "없음"}',
      tag: 'MainShell',
    );

    // 현재 경로 가져오기
    final String currentPath = GoRouterState.of(context).matchedLocation;

    // 현재 활성화된 탭 인덱스 계산
    int currentIndex = 0; // 기본값 홈

    if (currentPath == '/community') {
      currentIndex = 1;
    } else if (currentPath == '/group') {
      currentIndex = 3;
    } else if (currentPath == '/profile') {
      currentIndex = 4;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: currentIndex,
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
        profileImageUrl: currentUser?.image, // 현재 사용자의 이미지 URL 직접 전달
        onCreatePost: () {
          context.push('/community/write');
        },
        onCreateGroup: () {
          context.push('/group/create');
        },
      ),
    );
  }
}
