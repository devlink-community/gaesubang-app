// lib/auth/domain/repository/auth_fcm_repository.dart
import 'package:devlink_mobile_app/core/result/result.dart';

/// FCM 토큰 관리 Repository
abstract interface class AuthFCMRepository {
  /// 로그인 성공 시 FCM 토큰 등록
  /// 사용자 ID와 현재 디바이스의 FCM 토큰을 서버에 등록
  Future<Result<void>> registerFCMToken(String userId);

  /// 로그아웃 시 현재 디바이스의 FCM 토큰 해제
  /// 현재 디바이스에서만 알림을 받지 않도록 설정
  Future<Result<void>> unregisterCurrentDeviceFCMToken(String userId);

  /// 계정 삭제 시 모든 FCM 토큰 제거
  /// 해당 사용자의 모든 디바이스에서 알림을 받지 않도록 설정
  Future<Result<void>> removeAllFCMTokens(String userId);
}
