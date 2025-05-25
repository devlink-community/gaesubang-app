// lib/auth/data/data_source/auth_data_source.dart
import '../dto/summary_dto.dart';
import '../dto/user_dto.dart';

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
    required Map<String, dynamic> termsMap, // Map 형태로 변경
  });

  /// 현재 로그인 세션 확인
  Future<Map<String, dynamic>?> fetchCurrentUser();

  /// 로그아웃
  Future<void> signOut();

  /// 닉네임 중복 확인 (true: 사용 가능, false: 중복)
  Future<bool> checkNicknameAvailability(String nickname);

  /// 이메일 중복 확인 (true: 사용 가능, false: 중복)
  Future<bool> checkEmailAvailability(String email);

  /// 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail(String email);

  /// 계정삭제
  Future<void> deleteAccount(String email);

  /// 사용자 정보 업데이트
  Future<Map<String, dynamic>> updateUser({
    required String nickname,
    String? description,
    String? position,
    String? skills,
  });

  /// 사용자 이미지 업데이트
  Future<Map<String, dynamic>> updateUserImage(String imagePath);

  /// 인증 상태 변화 스트림
  Stream<Map<String, dynamic>?> get authStateChanges;

  /// 현재 인증 상태 확인
  Future<Map<String, dynamic>?> getCurrentAuthState();

  /// 특정 사용자 프로필 조회
  Future<UserDto> fetchUserProfile(String userId);

  // ===== 새로운 Activity/Summary 관련 메서드 =====

  /// 사용자 Summary 조회
  Future<SummaryDto?> fetchUserSummary(String userId);

  /// 사용자 Summary 업데이트
  Future<void> updateUserSummary({
    required String userId,
    required SummaryDto summary,
  });
}
