// lib/auth/domain/repository/auth_core_repository.dart
import 'package:devlink_mobile_app/auth/domain/model/user.dart';
import 'package:devlink_mobile_app/core/auth/auth_state.dart';
import 'package:devlink_mobile_app/core/result/result.dart';

/// 인증 핵심 기능 Repository
/// 로그인, 회원가입, 로그아웃 등 기본 인증 기능
abstract interface class AuthCoreRepository {
  /// 이메일, 비밀번호로 로그인
  Future<Result<User>> login({
    required String email,
    required String password,
  });

  /// 이메일, 비밀번호, 닉네임으로 회원가입
  Future<Result<User>> signup({
    required String email,
    required String password,
    required String nickname,
    String? agreedTermsId,
  });

  /// 현재 로그인된 유저 조회
  Future<Result<User>> getCurrentUser();

  /// 로그아웃
  Future<Result<void>> signOut();

  /// 비밀번호 재설정 이메일 발송
  Future<Result<void>> resetPassword(String email);

  /// 계정삭제
  Future<Result<void>> deleteAccount(String email);

  /// 닉네임 중복 확인 (true: 사용 가능, false: 중복)
  Future<Result<bool>> checkNicknameAvailability(String nickname);

  /// 이메일 중복 확인 (true: 사용 가능, false: 중복)
  Future<Result<bool>> checkEmailAvailability(String email);

  /// 인증 상태 변화 스트림
  Stream<AuthState> get authStateChanges;

  /// 현재 인증 상태 확인
  Future<AuthState> getCurrentAuthState();
}
