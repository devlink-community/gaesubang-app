import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../presentation/intro_screen_root.dart';

part 'intro_route.g.dart';

/// Intro 모듈의 라우트 정의
final introRoutes = [
  GoRoute(path: '/intro', builder: (context, state) => const IntroScreenRoot()),
];

@riverpod
GoRouter introRouter(IntroRouterRef ref) {
  return GoRouter(initialLocation: '/intro', routes: introRoutes);
}
