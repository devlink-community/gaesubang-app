// lib/auth/data/data_source/auth_data_source.dart
abstract interface class AuthDataSource {
  /// 이메일, 비밀번호로 로그인
  Future<Map<String, dynamic>> fetchLogin({
    required String email,
    required String password,
  });

  /// 이메일, 비밀번호, 닉네임으로 회원가입
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String nickname,
  });

  /// 현재 로그인 세션 확인
  Future<Map<String, dynamic>?> fetchCurrentUser();

  /// 로그아웃
  Future<void> signOut();

  /// 닉네임 중복 확인 (true: 사용 가능, false: 중복)
  Future<bool> checkNicknameAvailability(String nickname);

  /// 이메일 중복 확인 (true: 사용 가능, false: 중복)
  Future<bool> checkEmailAvailability(String email);

  /// 비밀번호 재설정 이메일 발송
  Future<void> resetPassword(String email);
}