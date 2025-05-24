// lib/auth/data/repository_impl/auth_fcm_repository_impl.dart
import 'package:devlink_mobile_app/auth/domain/repository/auth_fcm_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/notification/service/fcm_token_service.dart';

class AuthFCMRepositoryImpl implements AuthFCMRepository {
  final FCMTokenService _fcmTokenService;

  AuthFCMRepositoryImpl({
    required FCMTokenService fcmTokenService,
  }) : _fcmTokenService = fcmTokenService;

  @override
  Future<Result<void>> registerFCMToken(String userId) async {
    try {
      await _fcmTokenService.registerDeviceToken(userId);
      AppLogger.authInfo('FCM 토큰 등록 성공');
      return const Result.success(null);
    } catch (e, st) {
      AppLogger.error('FCM 토큰 등록 실패', error: e, stackTrace: st);
      return Result.error(
        Failure(
          FailureType.network,
          'FCM 토큰 등록에 실패했습니다',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> unregisterCurrentDeviceFCMToken(String userId) async {
    try {
      await _fcmTokenService.removeCurrentDeviceToken(userId);
      AppLogger.authInfo('현재 기기 FCM 토큰 해제 성공');
      return const Result.success(null);
    } catch (e, st) {
      AppLogger.error('FCM 토큰 해제 실패', error: e, stackTrace: st);
      return Result.error(
        Failure(
          FailureType.network,
          'FCM 토큰 해제에 실패했습니다',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> removeAllFCMTokens(String userId) async {
    try {
      await _fcmTokenService.removeAllUserTokens(userId);
      AppLogger.authInfo('모든 FCM 토큰 제거 성공');
      return const Result.success(null);
    } catch (e, st) {
      AppLogger.error('모든 FCM 토큰 제거 실패', error: e, stackTrace: st);
      return Result.error(
        Failure(
          FailureType.network,
          '모든 FCM 토큰 제거에 실패했습니다',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
