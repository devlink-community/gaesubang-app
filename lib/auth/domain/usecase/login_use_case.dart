// lib/auth/domain/usecase/login_use_case.dart
import 'package:devlink_mobile_app/auth/domain/model/user.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/notification/service/fcm_token_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LoginUseCase {
  final AuthRepository _repository;
  final FCMTokenService _fcmTokenService;

  LoginUseCase({
    required AuthRepository repository,
    required FCMTokenService fcmTokenService,
  }) : _repository = repository,
       _fcmTokenService = fcmTokenService;

  Future<AsyncValue<User>> execute({
    required String email,
    required String password,
  }) async {
    final result = await _repository.login(email: email, password: password);

    switch (result) {
      case Success(data: final user):
        // 로그인 성공 시 추가 FCM 처리 (백그라운드에서 실행)
        _handlePostLoginFCMTasks(user.uid);
        return AsyncData(user);
      case Error(failure: final error):
        return AsyncError(error, error.stackTrace ?? StackTrace.current);
    }
  }

  /// 로그인 후 FCM 관련 작업들을 백그라운드에서 처리
  void _handlePostLoginFCMTasks(String userId) {
    // 백그라운드에서 실행하여 로그인 성공 응답을 지연시키지 않음
    Future.delayed(Duration.zero, () async {
      try {
        // 1. 토큰 사용 시간 업데이트
        await _fcmTokenService.updateTokenLastUsed(userId);

        // 2. 만료된 토큰 정리 (선택적)
        await _fcmTokenService.cleanupExpiredTokens(userId);

        AppLogger.info('로그인 후 FCM 작업 완료', tag: 'LoginUseCase');
      } catch (e) {
        AppLogger.error(
          '로그인 후 FCM 작업 실패',
          tag: 'LoginUseCase',
          error: e,
        );
        // FCM 작업 실패는 무시 (로그인 자체에는 영향 없음)
      }
    });
  }
}
