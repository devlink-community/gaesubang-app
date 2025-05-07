import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_screen_root.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_screen_root.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../presentation/community_list/community_list_screen_root.dart';

final communityRoutes = [
  GoRoute(
    path: '/community',
    builder: (context, state) => const CommunityListScreenRoot(),
  ),
  GoRoute(
    path: '/community/write',
    builder: (_, __) => const CommunityWriteScreenRoot(),
  ),
  // 추가 상세/검색/글쓰기 경로는 이후 구현
  GoRoute(
    path: '/community/:id',
    builder:
        (context, state) =>
            CommunityDetailScreenRoot(postId: state.pathParameters['id']!),
  ),
];

final communityRouterProvider = Provider((ref) {
  return GoRouter(initialLocation: '/community', routes: communityRoutes);
});
