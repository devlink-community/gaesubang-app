import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../presentation/profile_edit/profile_edit_screen_root.dart';

part 'profile_edit_route.g.dart';

/// EditIntro 모듈의 라우트 정의
final profileEditRoutes = [
  GoRoute(
    path: '/edit-intro',
    builder: (context, state) => const ProfileEditScreenRoot(),
  ),
];

@riverpod
GoRouter profileEditRouter(Ref ref) {
  return GoRouter(initialLocation: '/edit-intro', routes: profileEditRoutes);
}
