// lib/group/module/group_router.dart
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/group_timer_screen_root.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/mock_screen/mock_screen.dart';
import 'package:go_router/go_router.dart';

final groupRoutes = [
  GoRoute(
    path: '/group',
    builder: (context, state) => const GroupListScreenRoot(),
  ),
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
];
