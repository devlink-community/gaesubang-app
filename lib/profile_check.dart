import 'package:devlink_mobile_app/setting/presentation/settings_screen_root.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // GoRouter 패키지 추가
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'auth/domain/model/member.dart';
import 'intro/domain/model/focus_time_stats.dart';
import 'intro/presentation/intro_screen.dart';
import 'intro/presentation/intro_state.dart';

void main() {
  // 1) 목(Member) 데이터
  final mockMember = Member(
    id: '0',
    email: 'mock@example.com',
    nickname: '닝닝',
    image:
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQpND_VCJ23YdyqjVjCgG0meg6C_Gx5wCOc3A&s',
    description:
        '안녕하세요! 이 편지는 영국으로 부터 시작되어 일년에 한바퀴 돌면서 받는 사람에게 행운을 주었고, 지금은 당신에게로 옮겨진 이편지는 4일 만에 당신 곁을 떠나야 합니다.',
    uid: '',
  );

  // 2) 목(FocusTimeStats) 데이터
  final mockStats = FocusTimeStats(
    totalMinutes: 330,
    weeklyMinutes: {
      '월': 50,
      '화': 60,
      '수': 45,
      '목': 55,
      '금': 70,
      '토': 30,
      '일': 20,
    },
  );

  // 3) IntroState에 목 데이터 모두 채우기
  final mockState = IntroState(
    userProfile: AsyncData(mockMember),
    focusStats: AsyncData(mockStats),
  );

  // 네비게이터 키 정의 (context 접근용) - router 정의 전에 선언
  final navigatorKey = GlobalKey<NavigatorState>();

  // GoRouter 설정
  final router = GoRouter(
    navigatorKey: navigatorKey, // 네비게이터 키 설정
    initialLocation: '/intro',
    routes: [
      GoRoute(
        path: '/intro',
        builder:
            (context, state) => IntroScreen(
              state: mockState,
              onAction: (action) async {
                final context = navigatorKey.currentContext;
                if (context != null) {
                  await context.push('/settings');
                }
              },
            ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreenRoot(),
      ),
    ],
  );

  runApp(
    ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        title: 'IntroScreen Demo',
      ),
    ),
  );
}
