import 'package:devlink_mobile_app/setting/presentation/settings_screen_root.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../edit_intro/presentation/screens/edit_intro_root.dart';
import '../presentation/intro_screen_root.dart';

part 'intro_route.g.dart';

/// Intro 모듈의 라우트 정의
final introRoutes = [
  GoRoute(path: '/intro', builder: (context, state) => const IntroScreenRoot()),
  // 설정 화면으로 이동하는 경로 추가
  GoRoute(
    path: '/settings',
    builder: (context, state) => const SettingsScreenRoot(),
  ),
];

@riverpod
GoRouter introRouter(IntroRouterRef ref) {
  return GoRouter(initialLocation: '/intro', routes: introRoutes);
}
