import 'package:devlink_mobile_app/notification/service/fcm_service.dart';
import 'package:devlink_mobile_app/notification/service/user_token_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fcm_di.g.dart';

/// FCM 서비스 제공자
@Riverpod(keepAlive: true)
FCMService fcmService(Ref ref) {
  return FCMService();
}

/// FCM 토큰 서비스 제공자
@Riverpod(keepAlive: true)
FCMTokenService fcmTokenService(Ref ref) {
  return FCMTokenService();
}
