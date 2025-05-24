import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/auth_validator.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/privacy_mask_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../dto/user_dto.dart';
import 'auth_data_source.dart';

class AuthFirebaseDataSource implements AuthDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  AuthFirebaseDataSource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance {
    AppLogger.authInfo('AuthFirebaseDataSource 초기화 완료');
  }

  // Users 컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// 사용자 정보와 타이머 활동을 병렬로 가져오는 최적화된 메서드
  Future<Map<String, dynamic>?> fetchCurrentUserWithTimerActivities() async {
    return ApiCallDecorator.wrap(
      'FirebaseAuth.fetchCurrentUserWithTimerActivities',
      () async {
        AppLogger.logStep(1, 4, 'Firebase 현재 사용자 확인');
        final user = _auth.currentUser;
        if (user == null) {
          AppLogger.debug('Firebase 현재 사용자 없음');
          return null;
        }

        AppLogger.logState('Firebase 사용자 정보', {
          'uid': user.uid,
          'email': user.email,
          'display_name': user.displayName,
          'photo_url': user.photoURL,
        });

        try {
          AppLogger.logStep(2, 4, '최근 30일 활동 범위 설정');
          // 최근 30일간의 활동만 조회 (성능 최적화)
          final thirtyDaysAgo = DateTime.now().subtract(
            const Duration(days: 30),
          );

          AppLogger.logStep(3, 4, 'Firebase 병렬 데이터 조회 시작');
          // Firebase 병렬 처리: 사용자 정보와 타이머 활동을 동시에 가져오기
          final results = await Future.wait([
            // 1. 사용자 문서 조회
            _usersCollection.doc(user.uid).get(),

            // 2. 타이머 활동 조회 (최근 30일)
            _usersCollection
                .doc(user.uid)
                .collection('timerActivities')
                .where(
                  'timestamp',
                  isGreaterThan: Timestamp.fromDate(thirtyDaysAgo),
                )
                .orderBy('timestamp', descending: true)
                .get(),
          ]);

          final userDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
          final activitiesSnapshot =
              results[1] as QuerySnapshot<Map<String, dynamic>>;

          if (!userDoc.exists) {
            AppLogger.error('Firebase 사용자 문서 없음: ${user.uid}');
            throw Exception(AuthErrorMessages.userDataNotFound);
          }

          final userData = userDoc.data()!;
          AppLogger.logStep(4, 4, '사용자 데이터 병합 및 반환');

          AppLogger.logState('Firebase 사용자 데이터 조회 결과', {
            'uid': user.uid,
            'nickname': userData['nickname'] ?? '',
            'streak_days': userData['streakDays'] ?? 0,
            'timer_activities_count': activitiesSnapshot.docs.length,
            'on_air': userData['onAir'] ?? false,
          });

          // 완전한 사용자 정보 구성
          final completeUserData = {
            'uid': user.uid,
            'email': userData['email'] ?? user.email,
            'nickname': userData['nickname'] ?? '',
            'image': userData['image'] ?? '',
            'description': userData['description'] ?? '',
            'onAir': userData['onAir'] ?? false,
            'position': userData['position'] ?? '',
            'skills': userData['skills'] ?? '',
            'streakDays': userData['streakDays'] ?? 0,
            'agreedTermId': userData['agreedTermId'],
            'isServiceTermsAgreed': userData['isServiceTermsAgreed'] ?? false,
            'isPrivacyPolicyAgreed': userData['isPrivacyPolicyAgreed'] ?? false,
            'isMarketingAgreed': userData['isMarketingAgreed'] ?? false,
            'agreedAt': userData['agreedAt'],
            'joingroup': userData['joingroup'] ?? [],

            // 타이머 활동 데이터 포함
            'timerActivities':
                activitiesSnapshot.docs
                    .map((doc) => {'id': doc.id, ...doc.data()})
                    .toList(),
          };

          AppLogger.authInfo('Firebase 완전한 사용자 데이터 조회 성공');
          return completeUserData;
        } catch (e, st) {
          AppLogger.error(
            'Firebase 사용자 정보와 활동 데이터 조회 실패',
            error: e,
            stackTrace: st,
          );
          throw Exception('사용자 정보와 활동 데이터를 불러오는데 실패했습니다: $e');
        }
      },
      params: {'uid': _auth.currentUser?.uid},
    );
  }

  @override
  Future<Map<String, dynamic>> fetchLogin({
    required String email,
    required String password,
  }) async {
    return ApiCallDecorator.wrap('FirebaseAuth.fetchLogin', () async {
      AppLogger.logBanner('Firebase 로그인 시작');
      AppLogger.logState('Firebase 로그인 요청', {
        'email': PrivacyMaskUtil.maskEmail(email), // 변경
        'password_length': password.length,
      });

      try {
        AppLogger.logStep(1, 3, 'Firebase Auth 로그인 시도');
        // Firebase Auth로 로그인
        final credential = await _auth.signInWithEmailAndPassword(
          email: email.toLowerCase(),
          password: password,
        );

        final user = credential.user;
        if (user == null) {
          AppLogger.error('Firebase Auth 로그인 성공했으나 사용자 객체 null');
          throw Exception(AuthErrorMessages.loginFailed);
        }

        AppLogger.logStep(2, 3, 'Firebase Auth 로그인 성공');
        AppLogger.logState('Firebase Auth 로그인 결과', {
          'uid': user.uid,
          'email': user.email,
          'email_verified': user.emailVerified,
        });

        AppLogger.logStep(3, 3, '완전한 사용자 데이터 조회');
        // 로그인 성공 시 병렬 처리로 완전한 데이터 반환
        final userData = await fetchCurrentUserWithTimerActivities();
        if (userData == null) {
          AppLogger.error('Firebase 로그인 후 사용자 데이터 조회 실패');
          throw Exception(AuthErrorMessages.userDataNotFound);
        }

        AppLogger.authInfo('Firebase 로그인 완료');
        return userData;
      } catch (e, st) {
        AppLogger.error('Firebase 로그인 실패', error: e, stackTrace: st);
        rethrow;
      }
    }, params: {'email': email});
  }

  @override
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String nickname,
    String? agreedTermsId,
  }) async {
    return ApiCallDecorator.wrap('FirebaseAuth.createUser', () async {
      AppLogger.logBanner('Firebase 회원가입 시작');
      AppLogger.logState('Firebase 회원가입 요청', {
        'email': PrivacyMaskUtil.maskEmail(email), // 변경
        'nickname': PrivacyMaskUtil.maskNickname(nickname), // 변경
        'password_length': password.length,
        'agreed_terms_id': agreedTermsId,
      });

      AppLogger.logStep(1, 6, '입력값 유효성 검사');
      // 유효성 검사
      AuthValidator.validateEmailFormat(email);
      AuthValidator.validateNicknameFormat(nickname);

      // 약관 동의 확인
      if (agreedTermsId == null || agreedTermsId.isEmpty) {
        AppLogger.error('약관 동의 누락');
        throw Exception(AuthErrorMessages.termsNotAgreed);
      }

      AppLogger.logStep(2, 6, '닉네임 중복 확인');
      // 닉네임 중복 확인 (Firestore에서만 확인 가능)
      final nicknameAvailable = await checkNicknameAvailability(nickname);
      if (!nicknameAvailable) {
        AppLogger.warning('닉네임 중복: ${PrivacyMaskUtil.maskNickname(nickname)}');
        throw Exception(AuthErrorMessages.nicknameAlreadyInUse);
      }

      AppLogger.logStep(3, 6, '이메일 중복 확인 (Firestore)');
      // 이메일 중복 확인은 Firestore에서만 가능 (Firebase Auth는 보안상 확인 불가)
      final emailAvailableInFirestore = await _checkEmailInFirestore(email);
      if (!emailAvailableInFirestore) {
        AppLogger.warning(
          '이메일 중복 (Firestore): ${PrivacyMaskUtil.maskEmail(email)}',
        );
        throw Exception(AuthErrorMessages.emailAlreadyInUse);
      }

      UserCredential? credential;
      User? user;

      try {
        AppLogger.logStep(4, 6, 'Firebase Auth 계정 생성');
        // Firebase Auth로 계정 생성 시도 (이때 실제 중복이 감지됨)
        credential = await _auth.createUserWithEmailAndPassword(
          email: email.toLowerCase(),
          password: password,
        );

        user = credential.user;
        if (user == null) {
          AppLogger.error('Firebase Auth 계정 생성 성공했으나 사용자 객체 null');
          throw Exception(AuthErrorMessages.accountCreationFailed);
        }

        AppLogger.authInfo('Firebase Auth 계정 생성 성공: ${user.uid}');
      } catch (e, st) {
        AppLogger.error('Firebase Auth 계정 생성 실패', error: e, stackTrace: st);

        // Firebase Auth 에러 코드별 처리
        if (e is FirebaseAuthException) {
          AppLogger.logState('Firebase Auth 에러 상세', {
            'error_code': e.code,
            'error_message': e.message,
            'email': email,
          });

          switch (e.code) {
            case 'email-already-in-use':
              throw Exception(AuthErrorMessages.emailAlreadyInUse);
            case 'weak-password':
              throw Exception('비밀번호가 너무 약합니다');
            case 'invalid-email':
              throw Exception('잘못된 이메일 형식입니다');
            case 'operation-not-allowed':
              throw Exception('이메일/비밀번호 인증이 비활성화되어 있습니다');
            case 'too-many-requests':
              throw Exception('너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요');
            default:
              throw Exception('계정 생성에 실패했습니다: ${e.message}');
          }
        }

        // 다른 종류의 예외
        throw Exception('계정 생성 중 오류가 발생했습니다: $e');
      }

      try {
        AppLogger.logStep(5, 6, 'Firebase Auth 프로필 설정');
        // Firebase Auth 프로필 정보 설정 (displayName)
        await user.updateDisplayName(nickname);

        AppLogger.logStep(6, 6, 'Firestore 사용자 데이터 저장');
        // Firestore에 완전한 사용자 정보 저장
        final now = Timestamp.now();
        final userData = {
          'uid': user.uid,
          'email': email.toLowerCase(),
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
          'agreedAt': now,
          'joingroup': <Map<String, dynamic>>[],
        };

        await _usersCollection.doc(user.uid).set(userData);

        AppLogger.authInfo('Firestore 사용자 데이터 저장 완료');
        AppLogger.logState('생성된 사용자 정보', {
          'uid': user.uid,
          'email': userData['email'],
          'nickname': userData['nickname'],
          'agreed_terms_id': userData['agreedTermId'],
        });

        // 회원가입 시에도 완전한 데이터 반환 (타이머 활동은 비어있음)
        final completeUserData = {
          ...userData,
          'timerActivities': <Map<String, dynamic>>[],
        };
        AppLogger.logBox('Firebase 회원가입 완료', '사용자: $nickname\n이메일: $email');
        return completeUserData;
      } catch (e, st) {
        AppLogger.error(
          'Firestore 저장 실패, Firebase Auth 계정 삭제 시도',
          error: e,
          stackTrace: st,
        );

        // Firestore 저장 실패 시 생성된 Firebase Auth 계정을 삭제
        try {
          await user.delete();
          AppLogger.authInfo('Firebase Auth 계정 롤백 완료');
        } catch (deleteError, deleteSt) {
          AppLogger.error(
            'Firebase Auth 계정 삭제 실패',
            error: deleteError,
            stackTrace: deleteSt,
          );
        }

        throw Exception('사용자 정보 저장에 실패했습니다: $e');
      }
    }, params: {'email': email, 'nickname': nickname});
  }

  /// Firestore에서만 이메일 중복 확인 (Firebase Auth 확인은 보안상 불가능)
  Future<bool> _checkEmailInFirestore(String email) async {
    AppLogger.debug(
      'Firestore 이메일 중복 확인 시작: ${PrivacyMaskUtil.maskEmail(email)}',
    );

    try {
      final normalizedEmail = email.toLowerCase();

      final query =
          await _usersCollection
              .where('email', isEqualTo: normalizedEmail)
              .limit(1)
              .get();

      final isAvailable = query.docs.isEmpty;

      AppLogger.logState('Firestore 이메일 중복 확인 결과', {
        'email': PrivacyMaskUtil.maskEmail(normalizedEmail),
        'is_available': isAvailable,
        'docs_found': query.docs.length,
      });

      return isAvailable;
    } catch (e, st) {
      AppLogger.error('Firestore 이메일 확인 중 오류', error: e, stackTrace: st);
      // 오류 발생 시 안전하게 사용 불가로 처리
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    return ApiCallDecorator.wrap('FirebaseAuth.fetchCurrentUser', () async {
      AppLogger.debug('Firebase 현재 사용자 조회');

      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.debug('Firebase 현재 사용자 없음');
        return null;
      }

      // 재시도 로직이 포함된 메서드 사용
      return await _fetchUserDataWithRetry(user.uid);
    });
  }

  @override
  Future<void> signOut() async {
    return ApiCallDecorator.wrap('FirebaseAuth.signOut', () async {
      AppLogger.authInfo('Firebase 로그아웃 실행');
      await _auth.signOut();
      AppLogger.authInfo('Firebase 로그아웃 완료');
    });
  }

  @override
  Future<bool> checkNicknameAvailability(String nickname) async {
    return ApiCallDecorator.wrap(
      'FirebaseAuth.checkNicknameAvailability',
      () async {
        AppLogger.debug(
          'Firebase 닉네임 중복 확인: ${PrivacyMaskUtil.maskNickname(nickname)}',
        );

        // 유효성 검사
        AuthValidator.validateNicknameFormat(nickname);

        // Firestore에서 닉네임 중복 확인
        final query =
            await _usersCollection
                .where('nickname', isEqualTo: nickname)
                .limit(1)
                .get();

        final isAvailable = query.docs.isEmpty;
        AppLogger.logState('Firebase 닉네임 중복 확인 결과', {
          'nickname': PrivacyMaskUtil.maskNickname(nickname),
          'is_available': isAvailable,
          'docs_found': query.docs.length,
        });

        return isAvailable;
      },
      params: {'nickname': nickname},
    );
  }

  @override
  Future<bool> checkEmailAvailability(String email) async {
    return ApiCallDecorator.wrap(
      'FirebaseAuth.checkEmailAvailability',
      () async {
        AppLogger.debug(
          'Firebase 이메일 중복 확인: ${PrivacyMaskUtil.maskEmail(email)}',
        );

        // 유효성 검사
        AuthValidator.validateEmailFormat(email);

        // Firebase Auth에서는 보안상 이메일 중복 확인이 제한됨
        // Firestore에서만 확인 가능하며, 실제 중복은 createUser 시점에서 감지됨
        final result = await _checkEmailInFirestore(email);
        AppLogger.debug(
          'Firebase 이메일 중복 확인 완료: ${PrivacyMaskUtil.maskEmail(email)} -> ${result ? "사용가능" : "사용불가"}',
        );
        return result;
      },
      params: {'email': email},
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    return ApiCallDecorator.wrap(
      'FirebaseAuth.sendPasswordResetEmail',
      () async {
        AppLogger.authInfo(
          'Firebase 비밀번호 재설정 이메일 전송: ${PrivacyMaskUtil.maskEmail(email)}',
        );

        // 유효성 검사
        AuthValidator.validateEmailFormat(email);

        await _auth.sendPasswordResetEmail(email: email.toLowerCase());
        AppLogger.authInfo('Firebase 비밀번호 재설정 이메일 전송 완료');
      },
      params: {'email': email},
    );
  }

  @override
  Future<void> deleteAccount(String email) async {
    return ApiCallDecorator.wrap('FirebaseAuth.deleteAccount', () async {
      AppLogger.logBanner('Firebase 계정 삭제 시작');

      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.error('Firebase 현재 사용자 없음 - 계정 삭제 불가');
        throw Exception(AuthErrorMessages.noLoggedInUser);
      }

      AppLogger.logState('Firebase 계정 삭제 대상', {
        'uid': user.uid,
        'email': email,
        'current_user_email': user.email,
      });

      AppLogger.logStep(1, 2, 'Firestore 사용자 데이터 삭제');
      // Firestore에서 사용자 데이터 삭제
      await _usersCollection.doc(user.uid).delete();
      AppLogger.authInfo('Firestore 사용자 데이터 삭제 완료');

      AppLogger.logStep(2, 2, 'Firebase Auth 계정 삭제');
      // Firebase Auth에서 계정 삭제
      await user.delete();
      AppLogger.logBox('Firebase 계정 삭제 완료', '이메일: $email');
    }, params: {'email': email});
  }

  @override
  Future<Map<String, dynamic>> saveTermsAgreement(
    Map<String, dynamic> termsData,
  ) async {
    return ApiCallDecorator.wrap('FirebaseAuth.saveTermsAgreement', () async {
      AppLogger.authInfo('Firebase 약관 동의 저장');
      AppLogger.logState('약관 동의 데이터', {
        'terms_id': termsData['id'],
        'service_agreed': termsData['isServiceTermsAgreed'],
        'privacy_agreed': termsData['isPrivacyPolicyAgreed'],
        'marketing_agreed': termsData['isMarketingAgreed'],
      });

      // 필수 약관 동의 여부 확인
      final isServiceTermsAgreed =
          termsData['isServiceTermsAgreed'] as bool? ?? false;
      final isPrivacyPolicyAgreed =
          termsData['isPrivacyPolicyAgreed'] as bool? ?? false;

      AuthValidator.validateRequiredTerms(
        isServiceTermsAgreed: isServiceTermsAgreed,
        isPrivacyPolicyAgreed: isPrivacyPolicyAgreed,
      );

      // 타임스탬프 추가
      termsData['agreedAt'] = Timestamp.now();
      termsData['id'] = 'terms_${DateTime.now().millisecondsSinceEpoch}';

      AppLogger.authInfo('Firebase 약관 동의 저장 완료: ${termsData['id']}');
      return termsData;
    }, params: {'termsId': termsData['id']});
  }

  @override
  Future<Map<String, dynamic>> fetchTermsInfo() async {
    return ApiCallDecorator.wrap('FirebaseAuth.fetchTermsInfo', () async {
      AppLogger.debug('Firebase 기본 약관 정보 조회');

      final termsInfo = {
        'id': 'terms_${DateTime.now().millisecondsSinceEpoch}',
        'isAllAgreed': false,
        'isServiceTermsAgreed': false,
        'isPrivacyPolicyAgreed': false,
        'isMarketingAgreed': false,
        'agreedAt': Timestamp.now(),
      };

      AppLogger.debug('Firebase 기본 약관 정보 생성 완료');
      return termsInfo;
    });
  }

  @override
  Future<Map<String, dynamic>?> getTermsInfo(String termsId) async {
    return ApiCallDecorator.wrap('FirebaseAuth.getTermsInfo', () async {
      AppLogger.debug('Firebase 특정 약관 정보 조회: $termsId');

      final termsInfo = {
        'id': termsId,
        'isAllAgreed': true,
        'isServiceTermsAgreed': true,
        'isPrivacyPolicyAgreed': true,
        'isMarketingAgreed': false,
        'agreedAt': Timestamp.now(),
      };

      AppLogger.debug('Firebase 특정 약관 정보 반환 완료');
      return termsInfo;
    }, params: {'termsId': termsId});
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTimerActivities(String userId) async {
    return ApiCallDecorator.wrap('FirebaseAuth.fetchTimerActivities', () async {
      AppLogger.debug('Firebase 타이머 활동 조회: $userId');

      // 이미 fetchCurrentUserWithTimerActivities에서 포함되므로
      // 별도 호출 시에만 동작하도록 유지
      final query =
          await _usersCollection
              .doc(userId)
              .collection('timerActivities')
              .orderBy('timestamp', descending: true)
              .get();

      final activities =
          query.docs.map((doc) {
            final data = doc.data();
            return {'id': doc.id, ...data};
          }).toList();

      AppLogger.authInfo('Firebase 타이머 활동 조회 완료: ${activities.length}개');
      return activities;
    }, params: {'userId': userId});
  }

  @override
  Future<void> saveTimerActivity(
    String userId,
    Map<String, dynamic> activityData,
  ) async {
    return ApiCallDecorator.wrap(
      'FirebaseAuth.saveTimerActivity',
      () async {
        AppLogger.debug(
          'Firebase 타이머 활동 저장: $userId, 타입: ${activityData['type']}',
        );

        // Firebase: users/{userId}/timerActivities 서브컬렉션에 저장
        final activityRef = _usersCollection
            .doc(userId)
            .collection('timerActivities');

        // ID가 있으면 해당 문서 업데이트, 없으면 자동 생성
        final activityId = activityData['id'] as String?;

        if (activityId != null) {
          AppLogger.debug('Firebase 기존 타이머 활동 업데이트: $activityId');
          await activityRef.doc(activityId).set({
            ...activityData,
            'timestamp':
                activityData['timestamp'] is DateTime
                    ? Timestamp.fromDate(activityData['timestamp'] as DateTime)
                    : activityData['timestamp'],
          });
        } else {
          AppLogger.debug('Firebase 새 타이머 활동 생성');
          await activityRef.add({
            ...activityData,
            'timestamp':
                activityData['timestamp'] is DateTime
                    ? Timestamp.fromDate(activityData['timestamp'] as DateTime)
                    : activityData['timestamp'],
          });
        }

        AppLogger.authInfo('Firebase 타이머 활동 저장 완료');
      },
      params: {'userId': userId, 'activityType': activityData['type']},
    );
  }

  @override
  Future<Map<String, dynamic>> updateUser({
    required String nickname,
    String? description,
    String? position,
    String? skills,
  }) async {
    return ApiCallDecorator.wrap('FirebaseAuth.updateUser', () async {
      AppLogger.logBanner('Firebase 사용자 프로필 업데이트 시작');

      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.error('Firebase 현재 사용자 없음 - 프로필 업데이트 불가');
        throw Exception(AuthErrorMessages.noLoggedInUser);
      }

      AppLogger.logState('Firebase 프로필 업데이트 요청', {
        'uid': user.uid,
        'nickname': nickname,
        'description_length': description?.length ?? 0,
        'position': position ?? 'null',
        'skills_length': skills?.length ?? 0,
      });

      // 닉네임 유효성 검사
      AuthValidator.validateNicknameFormat(nickname);

      AppLogger.logStep(1, 4, '현재 닉네임과 비교');
      // 현재 닉네임과 다른 경우에만 중복 확인
      final currentUserDoc = await _usersCollection.doc(user.uid).get();
      final currentNickname = currentUserDoc.data()?['nickname'] as String?;

      if (currentNickname != nickname) {
        AppLogger.logStep(2, 4, '닉네임 중복 확인');
        final nicknameAvailable = await checkNicknameAvailability(nickname);
        if (!nicknameAvailable) {
          AppLogger.warning('프로필 업데이트 - 닉네임 중복: $nickname');
          throw Exception(AuthErrorMessages.nicknameAlreadyInUse);
        }
        AppLogger.debug('닉네임 중복 확인 통과');
      } else {
        AppLogger.debug('닉네임 변경 없음 - 중복 확인 건너뜀');
      }

      AppLogger.logStep(3, 4, 'Firebase Auth 프로필 업데이트');
      // Firebase Auth 사용자 프로필 업데이트 (displayName)
      await user.updateDisplayName(nickname);

      // Firestore에 사용자 정보 업데이트
      final updateData = {
        'nickname': nickname,
        'description': description ?? '',
        'position': position ?? '',
        'skills': skills ?? '',
      };

      await _usersCollection.doc(user.uid).update(updateData);

      AppLogger.logStep(4, 4, 'Firebase Auth 프로필 재로드');
      // Firebase Auth 프로필 변경이 되었음을 확실히 하기 위해 재인증 트리거
      // 이는 authStateChanges 이벤트를 강제로 발생시킵니다
      await user.reload();

      AppLogger.authInfo('Firebase 프로필 정보 업데이트 완료: $nickname');

      // 업데이트된 완전한 사용자 정보 반환 (병렬 처리 활용)
      final updatedUserData = await fetchCurrentUserWithTimerActivities();
      if (updatedUserData == null) {
        AppLogger.error('프로필 업데이트 후 사용자 데이터 조회 실패');
        throw Exception(AuthErrorMessages.userDataNotFound);
      }

      AppLogger.logBox('Firebase 프로필 업데이트 완료', '사용자: $nickname');
      return updatedUserData;
    }, params: {'nickname': nickname});
  }

  @override
  Future<Map<String, dynamic>> updateUserImage(String imagePath) async {
    return ApiCallDecorator.wrap('FirebaseAuth.updateUserImage', () async {
      AppLogger.logBanner('Firebase 프로필 이미지 업데이트 시작');

      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.error('Firebase 현재 사용자 없음 - 이미지 업데이트 불가');
        throw Exception(AuthErrorMessages.noLoggedInUser);
      }

      AppLogger.logState('Firebase 이미지 업데이트 요청', {
        'uid': user.uid,
        'image_path': imagePath,
        'path_length': imagePath.length,
      });

      try {
        AppLogger.logStep(1, 8, '이미지 파일 검증');
        // 1. 이미지 파일 검증 (이미 UseCase에서 압축된 파일을 받음)
        final File imageFile = File(imagePath);
        if (!await imageFile.exists()) {
          AppLogger.error('이미지 파일을 찾을 수 없음: $imagePath');
          throw Exception('이미지 파일을 찾을 수 없습니다');
        }

        AppLogger.logStep(2, 8, '이미지 바이트 읽기');
        // 2. 이미지 바이트 읽기 (이미 압축된 상태)
        final Uint8List imageBytes = await imageFile.readAsBytes();

        AppLogger.logState('Firebase 업로드할 이미지 정보', {
          'file_size_kb': imageBytes.length ~/ 1024,
          'file_size_bytes': imageBytes.length,
          'is_compressed': true,
        });

        AppLogger.logStep(3, 8, 'Firebase Storage 경로 설정');
        // 3. Firebase Storage에 업로드
        final String fileName =
            'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String storagePath = 'users/${user.uid}/$fileName';

        final Reference storageRef = _storage.ref().child(storagePath);

        AppLogger.logStep(4, 8, '기존 프로필 이미지 삭제');
        // 기존 프로필 이미지가 있다면 삭제
        await _deleteExistingProfileImage(user.uid);

        AppLogger.logStep(5, 8, 'Firebase Storage 업로드');
        // 4. 새 이미지 업로드
        final UploadTask uploadTask = storageRef.putData(
          imageBytes,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'userId': user.uid,
              'uploadedAt': DateTime.now().toIso8601String(),
              'originalPath': imagePath,
              'compressedByUseCase': 'true',
            },
          ),
        );

        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        AppLogger.authInfo('Firebase Storage 이미지 업로드 완료: $downloadUrl');

        AppLogger.logStep(6, 8, 'Firebase Auth 프로필 이미지 업데이트');
        // 5. Firebase Auth 프로필 이미지 업데이트 (photoURL)
        await user.updatePhotoURL(downloadUrl);

        AppLogger.logStep(7, 8, 'Firestore 이미지 URL 업데이트');
        // 6. Firestore에 이미지 URL 업데이트
        await _usersCollection.doc(user.uid).update({'image': downloadUrl});

        AppLogger.logStep(8, 8, 'Firebase Auth 프로필 재로드');
        // 7. Firebase Auth 프로필 변경이 되었음을 확실히 하기 위해 재인증 트리거
        await user.reload();

        AppLogger.authInfo('Firebase 프로필 이미지 업데이트 완료');

        // 8. 업데이트된 완전한 사용자 정보 반환
        final updatedUserData = await fetchCurrentUserWithTimerActivities();
        if (updatedUserData == null) {
          AppLogger.error('이미지 업데이트 후 사용자 데이터 조회 실패');
          throw Exception(AuthErrorMessages.userDataNotFound);
        }

        AppLogger.logBox(
          'Firebase 프로필 이미지 업데이트 완료',
          '다운로드 URL: ${downloadUrl.substring(0, 50)}...',
        );
        return updatedUserData;
      } catch (e, stackTrace) {
        AppLogger.error(
          'Firebase 프로필 이미지 업데이트 실패',
          error: e,
          stackTrace: stackTrace,
        );
        AppLogger.logState('이미지 업데이트 실패 상세', {
          'image_path': imagePath,
          'error_type': e.runtimeType.toString(),
          'error_message': e.toString(),
        });

        // 사용자 친화적 에러 메시지
        if (e.toString().contains('network')) {
          throw Exception('네트워크 연결을 확인해주세요');
        } else if (e.toString().contains('permission')) {
          throw Exception('이미지 업로드 권한이 없습니다');
        } else if (e.toString().contains('quota')) {
          throw Exception('저장 공간이 부족합니다');
        } else if (e.toString().contains('file_size')) {
          throw Exception('이미지 파일이 너무 큽니다');
        } else {
          throw Exception('이미지 업로드에 실패했습니다');
        }
      }
    }, params: {'imagePath': imagePath});
  }

  /// 기존 프로필 이미지 삭제
  Future<void> _deleteExistingProfileImage(String userId) async {
    try {
      AppLogger.debug('기존 프로필 이미지 삭제 시도: $userId');

      final currentUserDoc = await _usersCollection.doc(userId).get();
      final currentImageUrl = currentUserDoc.data()?['image'] as String?;

      if (currentImageUrl != null &&
          currentImageUrl.isNotEmpty &&
          currentImageUrl.contains('firebase')) {
        final Reference oldImageRef = _storage.refFromURL(currentImageUrl);
        await oldImageRef.delete();
        AppLogger.authInfo('기존 프로필 이미지 삭제 완료');
      } else {
        AppLogger.debug('삭제할 기존 이미지 없음');
      }
    } catch (e, st) {
      AppLogger.warning('기존 이미지 삭제 실패 (무시함)', error: e, stackTrace: st);
      // 삭제 실패는 치명적이지 않으므로 예외를 던지지 않음
    }
  }

  // 인증 상태 변화 스트림 (Firebase userChanges() 사용)
  @override
  Stream<Map<String, dynamic>?> get authStateChanges {
    AppLogger.debug('Firebase 인증 상태 변화 스트림 시작');

    // Firebase Auth의 userChanges() 사용 - 프로필 정보 변경도 감지
    return _auth.userChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        AppLogger.authInfo('Firebase 인증 상태 변경: 로그아웃됨');
        return null;
      }

      AppLogger.authInfo(
        'Firebase 인증 상태 변경: 로그인됨 또는 프로필 변경 (${firebaseUser.uid})',
      );
      AppLogger.logState('Firebase 사용자 프로필 정보', {
        'uid': firebaseUser.uid,
        'display_name': firebaseUser.displayName,
        'photo_url': firebaseUser.photoURL,
        'email': firebaseUser.email,
        'email_verified': firebaseUser.emailVerified,
      });

      // 재시도 로직이 포함된 사용자 정보 가져오기
      return await _fetchUserDataWithRetry(firebaseUser.uid);
    }).distinct(); // 중복 이벤트 방지
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

        // fetchCurrentUserWithTimerActivities 호출
        final userData = await fetchCurrentUserWithTimerActivities();
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

        // 마지막 시도가 아니라면 재시도
        if (attempt < maxRetries) {
          // 점진적으로 증가하는 대기 시간 (500ms, 1s, 1.5s, 2s, 2.5s)
          final delayMs = 500 * attempt;
          AppLogger.debug('${delayMs}ms 후 재시도...');
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }

        // 최대 재시도 횟수 초과
        AppLogger.error(
          'Firebase 데이터 조회: 최대 재시도 횟수 초과 ($maxRetries회)',
          error: e,
          stackTrace: st,
        );
      }
    }

    // 모든 재시도가 실패한 경우 null 반환 (unauthenticated 상태로 처리)
    AppLogger.warning('Firebase 사용자 데이터 조회 최종 실패 - null 반환');
    return null;
  }

  // 현재 인증 상태 확인 (추가)
  @override
  Future<Map<String, dynamic>?> getCurrentAuthState() async {
    AppLogger.debug('Firebase 현재 인증 상태 확인');

    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.debug('Firebase 현재 사용자 없음');
      return null;
    }

    AppLogger.debug('Firebase 현재 사용자 있음: ${user.uid}');
    // 재시도 로직이 포함된 메서드 사용
    return await _fetchUserDataWithRetry(user.uid);
  }

  @override
  Future<UserDto> fetchUserProfile(String userId) async {
    return ApiCallDecorator.wrap('AuthFirebase.fetchUserProfile', () async {
      AppLogger.debug('Firebase 사용자 프로필 조회: $userId');

      try {
        // Firestore에서 특정 사용자 문서 조회
        final docSnapshot = await _usersCollection.doc(userId).get();

        if (!docSnapshot.exists) {
          AppLogger.warning('Firebase 사용자 문서 없음: $userId');
          throw Exception('사용자를 찾을 수 없습니다');
        }

        final userData = docSnapshot.data()!;
        userData['uid'] = docSnapshot.id; // 문서 ID를 uid로 설정

        AppLogger.authInfo('Firebase 사용자 프로필 조회 성공: $userId');
        AppLogger.logState('조회된 사용자 프로필', {
          'uid': userId,
          'nickname': userData['nickname'] ?? '',
          'email': userData['email'] ?? '',
          'position': userData['position'] ?? '',
        });

        return UserDto.fromJson(userData);
      } catch (e, st) {
        AppLogger.error('Firebase 사용자 프로필 조회 오류', error: e, stackTrace: st);
        throw Exception('사용자 프로필을 불러오는데 실패했습니다');
      }
    }, params: {'userId': userId});
  }
}
