import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../presentation/profile_setting/profile_setting_screen_root.dart';

part 'profile_setting_route.g.dart';

/// EditIntro 모듈의 라우트 정의
final profileSettingRoutes = [
  GoRoute(
    path: '/edit-intro',
    builder: (context, state) => const ProfileSettingScreenRoot(),
  ),
];

@riverpod
GoRouter profileSettingRouter(Ref ref) {
  return GoRouter(initialLocation: '/edit-intro', routes: profileSettingRoutes);
}
