import 'package:devlink_mobile_app/notification/service/fcm_service.dart';
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
import 'package:devlink_mobile_app/notification/service/fcm_token_service.dart';
=======
>>>>>>> 0daf644b (feat: fcm_di 추가 완료)
=======
import 'package:devlink_mobile_app/notification/service/user_token_service.dart';
>>>>>>> 7f497843 (fix: fcm di 토큰 서비스 제공 추가 완료)
=======
>>>>>>> 4ee0d781 (feat: fcm_di 추가 완료)
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fcm_di.g.dart';

/// FCM 서비스 제공자
@Riverpod(keepAlive: true)
FCMService fcmService(Ref ref) {
  return FCMService();
}
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 7f497843 (fix: fcm di 토큰 서비스 제공 추가 완료)

/// FCM 토큰 서비스 제공자
@Riverpod(keepAlive: true)
FCMTokenService fcmTokenService(Ref ref) {
  return FCMTokenService();
}
<<<<<<< HEAD
=======
>>>>>>> 0daf644b (feat: fcm_di 추가 완료)
=======
>>>>>>> 7f497843 (fix: fcm di 토큰 서비스 제공 추가 완료)
=======
>>>>>>> 4ee0d781 (feat: fcm_di 추가 완료)
