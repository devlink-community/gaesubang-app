import 'package:devlink_mobile_app/auth/data/dto/timer_activity_dto.dart';
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/core/auth/auth_state.dart';
import 'package:devlink_mobile_app/core/result/result.dart';

import '../model/user_focus_stats.dart';

abstract interface class AuthRepository {
  /// 이메일, 비밀번호로 로그인
  Future<Result<Member>> login({
    required String email,
    required String password,
  });

  /// 이메일, 비밀번호, 닉네임으로 회원가입 (약관 ID 추가)
  Future<Result<Member>> signup({
    required String email,
    required String password,
    required String nickname,
    String? agreedTermsId, // 약관 동의 ID 추가
  });

  /// 현재 로그인된 유저 조회
  Future<Result<Member>> getCurrentUser();

  /// 로그아웃
  Future<Result<void>> signOut();

  /// 닉네임 중복 확인 (true: 사용 가능, false: 중복)
  Future<Result<bool>> checkNicknameAvailability(String nickname);

  /// 이메일 중복 확인 (true: 사용 가능, false: 중복)
  Future<Result<bool>> checkEmailAvailability(String email);

  /// 비밀번호 재설정 이메일 발송
  Future<Result<void>> resetPassword(String email);

  /// 계정삭제
  Future<Result<void>> deleteAccount(String email);

  /// 약관 동의 정보 저장
  Future<Result<TermsAgreement>> saveTermsAgreement(
    TermsAgreement termsAgreement,
  );

  /// 약관 정보 조회
  Future<Result<TermsAgreement?>> getTermsInfo(String? termsId);

  /// 사용자의 타이머 활동 로그 조회
  Future<Result<List<TimerActivityDto>>> getTimerActivities(String userId);

  /// 타이머 활동 로그 추가
  Future<Result<void>> saveTimerActivity(
    String userId,
    TimerActivityDto activity,
  );

  /// 프로필 정보 업데이트
  Future<Result<Member>> updateProfile({
    required String nickname,
    String? description,
    String? position,
    String? skills,
  });

  /// 프로필 이미지 업데이트
  Future<Result<Member>> updateProfileImage(String imagePath);

  // === 새로 추가된 인증 상태 관련 메서드 ===

  /// 인증 상태 변화 스트림
  /// Firebase Auth 또는 Mock의 상태 변화를 실시간으로 감지
  Stream<AuthState> get authStateChanges;

  /// 현재 인증 상태 확인
  /// 라우터에서 초기 리다이렉트 시 사용
  Future<AuthState> getCurrentAuthState();

  // === FCM 토큰 관리 메서드 추가 ===

  /// 로그인 성공 시 FCM 토큰 등록
  /// 사용자 ID와 현재 디바이스의 FCM 토큰을 서버에 등록
  Future<Result<void>> registerFCMToken(String userId);

  /// 로그아웃 시 현재 디바이스의 FCM 토큰 해제
  /// 현재 디바이스에서만 알림을 받지 않도록 설정
  Future<Result<void>> unregisterCurrentDeviceFCMToken(String userId);

  /// 계정 삭제 시 모든 FCM 토큰 제거
  /// 해당 사용자의 모든 디바이스에서 알림을 받지 않도록 설정
  Future<Result<void>> removeAllFCMTokens(String userId);

  Future<Result<Member>> getUserProfile(String userId);

  /// 사용자 집중시간 통계 업데이트
  /// 그룹 출석부에서 계산된 시간들을 User 문서에 저장
  Future<Result<void>> updateUserFocusStats({
    required String userId,
    required UserFocusStats stats,
  });
}
