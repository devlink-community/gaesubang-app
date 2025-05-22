import 'package:devlink_mobile_app/notification/service/fcm_service.dart';
<<<<<<< HEAD
import 'package:devlink_mobile_app/notification/service/fcm_token_service.dart';
=======
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
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
=======
import 'package:devlink_mobile_app/notification/service/user_token_service.dart';
>>>>>>> 7af52224 (fix: fcm di 토큰 서비스 제공 추가 완료)
=======
import 'package:devlink_mobile_app/notification/service/fcm_token_service.dart';
>>>>>>> 663d40c9 (fix: fcm_di 수정 완료)
=======
import 'package:devlink_mobile_app/notification/service/fcm_token_service.dart';
>>>>>>> 93342ffe988801372968965945de141989ff1d54
>>>>>>> 08972b3075e1330dbbff0f8ace57078a8d96729d
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fcm_di.g.dart';

/// FCM 서비스 제공자
@Riverpod(keepAlive: true)
FCMService fcmService(Ref ref) {
  return FCMService();
}
<<<<<<< HEAD
=======
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 7f497843 (fix: fcm di 토큰 서비스 제공 추가 완료)
=======
>>>>>>> 7af52224 (fix: fcm di 토큰 서비스 제공 추가 완료)
=======
>>>>>>> 93342ffe988801372968965945de141989ff1d54
>>>>>>> 08972b3075e1330dbbff0f8ace57078a8d96729d

/// FCM 토큰 서비스 제공자
@Riverpod(keepAlive: true)
FCMTokenService fcmTokenService(Ref ref) {
  return FCMTokenService();
}
<<<<<<< HEAD
=======
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 0daf644b (feat: fcm_di 추가 완료)
=======
>>>>>>> 7f497843 (fix: fcm di 토큰 서비스 제공 추가 완료)
=======
>>>>>>> 4ee0d781 (feat: fcm_di 추가 완료)
=======
>>>>>>> 7af52224 (fix: fcm di 토큰 서비스 제공 추가 완료)
=======
>>>>>>> 93342ffe988801372968965945de141989ff1d54
>>>>>>> 08972b3075e1330dbbff0f8ace57078a8d96729d
