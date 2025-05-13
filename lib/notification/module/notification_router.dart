import 'package:devlink_mobile_app/notification/presentation/notification_screen_root.dart';
import 'package:go_router/go_router.dart';

// 알림 관련 라우트 정의
final notificationRoutes = [
  GoRoute(
    path: '/notifications',
    builder: (context, state) => const NotificationScreenRoot(),
  ),
];
