import 'package:devlink_mobile_app/group/presentation/group_list/group_list_screen_root.dart';
import 'package:go_router/go_router.dart';

final groupRoutes = [
  GoRoute(
    path: '/group',
    builder: (context, state) => const GroupListScreenRoot(),
  ),
];
