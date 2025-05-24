// lib/auth/data/data_source/auth_data_source.dart
import '../dto/activity_dto.dart';
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
    String? agreedTermsId,
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

  /// 약관 동의 정보 저장
  Future<Map<String, dynamic>> saveTermsAgreement(
    Map<String, dynamic> termsData,
  );

  /// 약관 정보 조회
  Future<Map<String, dynamic>> fetchTermsInfo();

  /// 특정 약관 정보 조회
  Future<Map<String, dynamic>?> getTermsInfo(String termsId);

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

  /// 그룹 Activity 조회
  Future<ActivityDto?> fetchGroupActivity({
    required String groupId,
    required String userId,
  });

  /// 그룹 Activity 업데이트
  Future<void> updateGroupActivity({
    required String groupId,
    required String userId,
    required ActivityDto activity,
  });

  /// 그룹 Activity 실시간 스트림
  Stream<ActivityDto> streamGroupActivity({
    required String groupId,
    required String userId,
  });

  /// 그룹의 모든 멤버 Activity 스트림
  Stream<List<ActivityDto>> streamGroupMembersActivities(String groupId);

  /// 월별 통계 조회
  Future<Map<String, dynamic>?> fetchMonthlyStats({
    required String groupId,
    required String yearMonth,
  });

  // ===== Deprecated 메서드 (추후 삭제 예정) =====

  /// @deprecated - Summary/Activity 사용
  Future<List<Map<String, dynamic>>> fetchTimerActivities(String userId);

  /// @deprecated - updateGroupActivity 사용
  Future<void> saveTimerActivity(
    String userId,
    Map<String, dynamic> activityData,
  );
}
