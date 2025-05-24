// lib/auth/data/data_source/auth_firebase_data_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/auth/data/data_source/firebase/auth_core_firebase.dart';
import 'package:devlink_mobile_app/auth/data/data_source/firebase/user_activity_firebase.dart';
import 'package:devlink_mobile_app/auth/data/data_source/firebase/user_profile_firebase.dart';
import 'package:devlink_mobile_app/auth/data/data_source/firebase/user_terms_firebase.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../dto/summary_dto.dart';
import '../dto/user_dto.dart';
import 'auth_data_source.dart';

/// Firebase 기반 인증 데이터소스 구현 (Facade 패턴)
class AuthFirebaseDataSource implements AuthDataSource {
  final AuthCoreFirebase _authCore;
  final UserProfileFirebase _userProfile;
  final UserActivityFirebase _userActivity;
  final UserTermsFirebase _userTerms;

  AuthFirebaseDataSource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _authCore = AuthCoreFirebase(
         auth: auth,
         firestore: firestore,
       ),
       _userProfile = UserProfileFirebase(
         auth: auth,
         firestore: firestore,
         storage: storage,
       ),
       _userActivity = UserActivityFirebase(
         firestore: firestore,
       ),
       _userTerms = UserTermsFirebase(
         firestore: firestore,
       ) {
    AppLogger.authInfo('AuthFirebaseDataSource (Facade) 초기화 완료');
  }

  @override
  Future<Map<String, dynamic>> fetchLogin({
    required String email,
    required String password,
  }) async {
    // 1. 로그인 수행
    final authResult = await _authCore.signInWithEmailPassword(
      email: email,
      password: password,
    );

    final userId = authResult['uid'] as String;

    // 2. 사용자 프로필 조회
    final userData = await _userProfile.fetchUserProfile(userId);
    if (userData == null) {
      throw Exception('사용자 데이터를 찾을 수 없습니다');
    }

    // 3. Summary 정보 조회
    final summaryData = await _userActivity.fetchUserSummary(userId);

    // 4. 데이터 병합
    userData['summary'] = summaryData;

    AppLogger.authInfo('로그인 완료 - 전체 사용자 데이터 조회 성공');
    return userData;
  }

  @override
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String nickname,
    String? agreedTermsId,
  }) async {
    // 1. 입력값 검증 및 중복 확인
    final nicknameAvailable = await _authCore.checkNicknameAvailability(
      nickname,
    );
    if (!nicknameAvailable) {
      throw Exception('이미 사용 중인 닉네임입니다');
    }

    final emailAvailable = await _authCore.checkEmailAvailabilityInFirestore(
      email,
    );
    if (!emailAvailable) {
      throw Exception('이미 사용 중인 이메일입니다');
    }

    // 2. Firebase Auth 계정 생성
    final user = await _authCore.createUserWithEmailPassword(
      email: email,
      password: password,
      nickname: nickname,
      agreedTermsId: agreedTermsId ?? '',
    );

    try {
      // 3. Firestore에 사용자 프로필 생성
      await _userProfile.createUserProfile(
        userId: user.uid,
        email: email,
        nickname: nickname,
        agreedTermsId: agreedTermsId ?? '',
      );

      // 4. 기본 Summary 생성
      final defaultSummary = await _userActivity.fetchUserSummary(user.uid);

      // 5. 생성된 사용자 데이터 반환
      final userData = {
        'uid': user.uid,
        'email': email,
        'nickname': nickname,
        'image': '',
        'description': '',
        'onAir': false,
        'position': '',
        'skills': '',
        'streakDays': 0,
        'agreedTermId': agreedTermsId,
        'isServiceTermsAgreed': true,
        'isPrivacyPolicyAgreed': true,
        'isMarketingAgreed': false,
        'agreedAt': Timestamp.now(),
        'joingroup': <Map<String, dynamic>>[],
        'summary': defaultSummary,
      };

      AppLogger.authInfo('회원가입 완료 - 사용자 데이터 생성 성공');
      return userData;
    } catch (e) {
      // 실패 시 생성된 Firebase Auth 계정 삭제
      AppLogger.error('Firestore 저장 실패, Firebase Auth 계정 삭제 시도', error: e);
      try {
        await user.delete();
        AppLogger.authInfo('Firebase Auth 계정 롤백 완료');
      } catch (deleteError) {
        AppLogger.error('Firebase Auth 계정 삭제 실패', error: deleteError);
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    final currentUser = _authCore.currentUser;
    if (currentUser == null) {
      AppLogger.debug('현재 로그인된 사용자 없음');
      return null;
    }

    // 사용자 프로필 조회
    final userData = await _userProfile.fetchUserProfile(currentUser.uid);
    if (userData == null) {
      return null;
    }

    // Summary 정보 조회
    final summaryData = await _userActivity.fetchUserSummary(currentUser.uid);
    userData['summary'] = summaryData;

    return userData;
  }

  @override
  Future<void> signOut() async {
    await _authCore.signOut();
  }

  @override
  Future<bool> checkNicknameAvailability(String nickname) async {
    return await _authCore.checkNicknameAvailability(nickname);
  }

  @override
  Future<bool> checkEmailAvailability(String email) async {
    return await _authCore.checkEmailAvailabilityInFirestore(email);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _authCore.sendPasswordResetEmail(email);
  }

  @override
  Future<void> deleteAccount(String email) async {
    final currentUser = _authCore.currentUser;
    if (currentUser == null) {
      throw Exception('로그인된 사용자가 없습니다');
    }

    await _authCore.deleteAccount(currentUser.uid);
  }

  @override
  Future<Map<String, dynamic>> saveTermsAgreement(
    Map<String, dynamic> termsData,
  ) async {
    final savedTerms = await _userTerms.saveTermsAgreement(termsData);

    // 현재 사용자가 있으면 사용자 문서도 업데이트
    final currentUser = _authCore.currentUser;
    if (currentUser != null) {
      await _userTerms.updateUserTermsAgreement(
        userId: currentUser.uid,
        termsData: savedTerms,
      );
    }

    return savedTerms;
  }

  @override
  Future<Map<String, dynamic>> fetchTermsInfo() async {
    return await _userTerms.fetchDefaultTermsInfo();
  }

  @override
  Future<Map<String, dynamic>?> getTermsInfo(String termsId) async {
    return await _userTerms.getTermsInfo(termsId);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTimerActivities(String userId) async {
    // 레거시 메서드 - 새 구조에서는 사용하지 않음
    AppLogger.warning(
      'fetchTimerActivities는 deprecated입니다. Summary/Activity를 사용하세요.',
    );
    return [];
  }

  @override
  Future<void> saveTimerActivity(
    String userId,
    Map<String, dynamic> activityData,
  ) async {
    // 레거시 메서드 - 새 구조에서는 사용하지 않음
    AppLogger.warning(
      'saveTimerActivity는 deprecated입니다. updateGroupActivity를 사용하세요.',
    );
  }

  @override
  Future<Map<String, dynamic>> updateUser({
    required String nickname,
    String? description,
    String? position,
    String? skills,
  }) async {
    final currentUser = _authCore.currentUser;
    if (currentUser == null) {
      throw Exception('로그인된 사용자가 없습니다');
    }

    // 프로필 업데이트
    await _userProfile.updateUserProfile(
      userId: currentUser.uid,
      nickname: nickname,
      description: description,
      position: position,
      skills: skills,
    );

    // 업데이트된 전체 사용자 데이터 반환
    final updatedUserData = await fetchCurrentUser();
    if (updatedUserData == null) {
      throw Exception('업데이트된 사용자 데이터를 가져올 수 없습니다');
    }

    return updatedUserData;
  }

  @override
  Future<Map<String, dynamic>> updateUserImage(String imagePath) async {
    final currentUser = _authCore.currentUser;
    if (currentUser == null) {
      throw Exception('로그인된 사용자가 없습니다');
    }

    // 이미지 업데이트
    await _userProfile.updateProfileImage(
      userId: currentUser.uid,
      imagePath: imagePath,
    );

    // 업데이트된 전체 사용자 데이터 반환
    final updatedUserData = await fetchCurrentUser();
    if (updatedUserData == null) {
      throw Exception('업데이트된 사용자 데이터를 가져올 수 없습니다');
    }

    return updatedUserData;
  }

  @override
  Stream<Map<String, dynamic>?> get authStateChanges {
    return _authCore.userChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        AppLogger.authInfo('Firebase 인증 상태 변경: 로그아웃됨');
        return null;
      }

      AppLogger.authInfo('Firebase 인증 상태 변경: 로그인됨 (${firebaseUser.uid})');

      // 재시도 로직을 포함한 사용자 정보 가져오기
      return await _fetchUserDataWithRetry(firebaseUser.uid);
    }).distinct();
  }

  @override
  Future<Map<String, dynamic>?> getCurrentAuthState() async {
    final currentUser = _authCore.currentUser;
    if (currentUser == null) {
      return null;
    }

    return await _fetchUserDataWithRetry(currentUser.uid);
  }

  @override
  Future<UserDto> fetchUserProfile(String userId) async {
    return await _userProfile.fetchOtherUserProfile(userId);
  }

  // ===== 새로운 Activity/Summary 관련 메서드 구현 =====

  @override
  Future<SummaryDto?> fetchUserSummary(String userId) async {
    final summaryData = await _userActivity.fetchUserSummary(userId);
    if (summaryData == null) return null;

    return SummaryDto.fromJson(summaryData);
  }

  @override
  Future<void> updateUserSummary({
    required String userId,
    required SummaryDto summary,
  }) async {
    await _userActivity.updateUserSummary(
      userId: userId,
      summary: summary,
    );
  }

  /// 재시도 로직이 포함된 사용자 데이터 가져오기
  Future<Map<String, dynamic>?> _fetchUserDataWithRetry(
    String uid, {
    int maxRetries = 5,
  }) async {
    AppLogger.debug('Firebase 사용자 데이터 재시도 로직 시작: $uid (최대 $maxRetries회)');

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        AppLogger.debug('Firebase 데이터 조회 시도 $attempt/$maxRetries: $uid');

        final userData = await fetchCurrentUser();
        if (userData != null) {
          AppLogger.authInfo(
            'Firebase 사용자 데이터 조회 성공 (시도: $attempt/$maxRetries)',
          );
          return userData;
        }
      } catch (e, st) {
        AppLogger.warning(
          'Firebase 데이터 조회 시도 $attempt/$maxRetries 실패',
          error: e,
          stackTrace: st,
        );

        if (attempt < maxRetries) {
          final delayMs = 500 * attempt;
          AppLogger.debug('${delayMs}ms 후 재시도...');
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }

        AppLogger.error(
          'Firebase 데이터 조회: 최대 재시도 횟수 초과 ($maxRetries회)',
          error: e,
          stackTrace: st,
        );
      }
    }

    AppLogger.warning('Firebase 사용자 데이터 조회 최종 실패 - null 반환');
    return null;
  }
}
