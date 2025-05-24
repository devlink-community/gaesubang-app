// lib/auth/data/data_source/firebase/auth_core_firebase.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/auth_validator.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/privacy_mask_util.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Auth 핵심 기능 (로그인, 회원가입, 로그아웃 등)
class AuthCoreFirebase {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthCoreFirebase({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// 이메일/비밀번호 로그인
  Future<Map<String, dynamic>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return ApiCallDecorator.wrap(
      'AuthCoreFirebase.signInWithEmailPassword',
      () async {
        AppLogger.logBanner('Firebase 로그인 시작');
        AppLogger.logState('Firebase 로그인 요청', {
          'email': PrivacyMaskUtil.maskEmail(email),
          'password_length': password.length,
        });

        try {
          AppLogger.logStep(1, 2, 'Firebase Auth 로그인 시도');
          final credential = await _auth.signInWithEmailAndPassword(
            email: email.toLowerCase(),
            password: password,
          );

          final user = credential.user;
          if (user == null) {
            AppLogger.error('Firebase Auth 로그인 성공했으나 사용자 객체 null');
            throw Exception(AuthErrorMessages.loginFailed);
          }

          AppLogger.logStep(2, 2, 'Firebase Auth 로그인 성공');
          AppLogger.logState('Firebase Auth 로그인 결과', {
            'uid': user.uid,
            'email': user.email,
            'email_verified': user.emailVerified,
          });

          AppLogger.authInfo('Firebase 로그인 완료');
          return {
            'uid': user.uid,
            'email': user.email,
            'emailVerified': user.emailVerified,
          };
        } catch (e, st) {
          AppLogger.error('Firebase 로그인 실패', error: e, stackTrace: st);
          rethrow;
        }
      },
      params: {'email': PrivacyMaskUtil.maskEmail(email)},
    );
  }

  /// 회원가입
  Future<User> createUserWithEmailPassword({
    required String email,
    required String password,
    required String nickname,
    required String agreedTermsId,
  }) async {
    return ApiCallDecorator.wrap(
      'AuthCoreFirebase.createUserWithEmailPassword',
      () async {
        AppLogger.logBanner('Firebase 회원가입 시작');
        AppLogger.logState('Firebase 회원가입 요청', {
          'email': PrivacyMaskUtil.maskEmail(email),
          'nickname': PrivacyMaskUtil.maskNickname(nickname),
          'password_length': password.length,
          'agreed_terms_id': agreedTermsId,
        });

        AppLogger.logStep(1, 3, '입력값 유효성 검사');
        AuthValidator.validateEmailFormat(email);
        AuthValidator.validateNicknameFormat(nickname);

        if (agreedTermsId.isEmpty) {
          AppLogger.error('약관 동의 누락');
          throw Exception(AuthErrorMessages.termsNotAgreed);
        }

        try {
          AppLogger.logStep(2, 3, 'Firebase Auth 계정 생성');
          final credential = await _auth.createUserWithEmailAndPassword(
            email: email.toLowerCase(),
            password: password,
          );

          final user = credential.user;
          if (user == null) {
            AppLogger.error('Firebase Auth 계정 생성 성공했으나 사용자 객체 null');
            throw Exception(AuthErrorMessages.accountCreationFailed);
          }

          AppLogger.logStep(3, 3, 'Firebase Auth 프로필 설정');
          await user.updateDisplayName(nickname);

          AppLogger.authInfo('Firebase Auth 계정 생성 성공: ${user.uid}');
          return user;
        } catch (e, st) {
          AppLogger.error('Firebase Auth 계정 생성 실패', error: e, stackTrace: st);

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

          throw Exception('계정 생성 중 오류가 발생했습니다: $e');
        }
      },
      params: {
        'email': PrivacyMaskUtil.maskEmail(email),
        'nickname': PrivacyMaskUtil.maskNickname(nickname),
      },
    );
  }

  /// 로그아웃
  Future<void> signOut() async {
    return ApiCallDecorator.wrap('AuthCoreFirebase.signOut', () async {
      AppLogger.authInfo('Firebase 로그아웃 실행');
      await _auth.signOut();
      AppLogger.authInfo('Firebase 로그아웃 완료');
    });
  }

  /// 비밀번호 재설정 이메일 발송
  Future<void> sendPasswordResetEmail(String email) async {
    return ApiCallDecorator.wrap(
      'AuthCoreFirebase.sendPasswordResetEmail',
      () async {
        AppLogger.authInfo(
          'Firebase 비밀번호 재설정 이메일 전송: ${PrivacyMaskUtil.maskEmail(email)}',
        );

        AuthValidator.validateEmailFormat(email);
        await _auth.sendPasswordResetEmail(email: email.toLowerCase());
        AppLogger.authInfo('Firebase 비밀번호 재설정 이메일 전송 완료');
      },
      params: {'email': PrivacyMaskUtil.maskEmail(email)},
    );
  }

  /// 계정 삭제
  Future<void> deleteAccount(String userId) async {
    return ApiCallDecorator.wrap(
      'AuthCoreFirebase.deleteAccount',
      () async {
        AppLogger.logBanner('Firebase 계정 삭제 시작');

        final user = _auth.currentUser;
        if (user == null || user.uid != userId) {
          AppLogger.error('Firebase 현재 사용자 없음 또는 ID 불일치 - 계정 삭제 불가');
          throw Exception(AuthErrorMessages.noLoggedInUser);
        }

        AppLogger.logStep(1, 2, 'Firestore 사용자 데이터 삭제');
        await _usersCollection.doc(userId).delete();
        AppLogger.authInfo('Firestore 사용자 데이터 삭제 완료');

        AppLogger.logStep(2, 2, 'Firebase Auth 계정 삭제');
        await user.delete();
        AppLogger.logBox('Firebase 계정 삭제 완료', 'userId: $userId');
      },
      params: {'userId': PrivacyMaskUtil.maskUserId(userId)},
    );
  }

  /// 현재 사용자 가져오기
  User? get currentUser => _auth.currentUser;

  /// 인증 상태 변화 스트림
  Stream<User?> get userChanges => _auth.userChanges();

  /// 닉네임 중복 확인
  Future<bool> checkNicknameAvailability(String nickname) async {
    return ApiCallDecorator.wrap(
      'AuthCoreFirebase.checkNicknameAvailability',
      () async {
        AppLogger.debug(
          'Firebase 닉네임 중복 확인: ${PrivacyMaskUtil.maskNickname(nickname)}',
        );

        AuthValidator.validateNicknameFormat(nickname);

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
      params: {'nickname': PrivacyMaskUtil.maskNickname(nickname)},
    );
  }

  /// Firestore에서 이메일 중복 확인
  Future<bool> checkEmailAvailabilityInFirestore(String email) async {
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
      return false;
    }
  }
}
