// lib/core/layout/main_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../auth/auth_provider.dart';
import '../component/navigation_bar.dart';

/// 메인 레이아웃을 관리하는 Shell 위젯
/// 하단 네비게이션 바와 콘텐츠 영역을 포함
class MainShell extends ConsumerWidget {
  /// 자식 위젯 (라우터에서 전달된 현재 화면)
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 현재 사용자 정보 구독 (라우터 대신 여기서 처리)
    final currentUser = ref.watch(currentUserProvider);
    final profileImageUrl = currentUser?.image;

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
          context.push('/community/write');
        },
        onCreateGroup: () {
          context.push('/group/create');
        },
      ),
    );
  }
}
