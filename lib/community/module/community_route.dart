import 'package:go_router/go_router.dart';
import '../presentation/community_list/community_list_screen_root.dart';

final communityRoutes = [
  GoRoute(
    path: '/community',
    builder: (context, state) => const CommunityListScreenRoot(),
  ),
  // 추가 상세/검색/글쓰기 경로는 이후 구현
];
