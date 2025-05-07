import 'package:devlink_mobile_app/group/presentation/group_timer/group_timer_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/mock_screen/mock_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 그룹 타이머 테스트용 메인 파일
///
/// 명령어: flutter run -t lib/group/group_timer_test.dart
void main() {
  // 테스트용 그룹 ID
  const testGroupId = 'group_0';

  // 테스트용 라우터 설정
  final router = GoRouter(
    initialLocation: '/group/$testGroupId',
    routes: [
      GoRoute(
        path: '/group/:id',
        builder:
            (context, state) =>
                GroupTimerScreenRoot(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/group/:id/attendance',
        builder:
            (context, state) =>
                MockGroupAttendanceScreen(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/group/:id/settings',
        builder:
            (context, state) =>
                MockGroupSettingsScreen(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/user/:id/profile',
        builder:
            (context, state) =>
                MockUserProfileScreen(userId: state.pathParameters['id']!),
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          body: Center(child: Text('경로를 찾을 수 없습니다: ${state.fullPath}')),
        ),
  );

  runApp(
    ProviderScope(
      child: MaterialApp.router(
        title: '그룹 타이머 테스트',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        routerConfig: router,
      ),
    ),
  );
}
