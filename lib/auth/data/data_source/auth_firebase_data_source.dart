// lib/auth/data/data_source/auth_firebase_data_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/auth_validator.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_data_source.dart';

class AuthFirebaseDataSource implements AuthDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthFirebaseDataSource({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  // Users 컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// 사용자 정보와 타이머 활동을 병렬로 가져오는 최적화된 메서드
  Future<Map<String, dynamic>?> fetchCurrentUserWithTimerActivities() async {
    return ApiCallDecorator.wrap(
      'FirebaseAuth.fetchCurrentUserWithTimerActivities',
      () async {
        final user = _auth.currentUser;
        if (user == null) return null;

        try {
          // 최근 30일간의 활동만 조회 (성능 최적화)
          final thirtyDaysAgo = DateTime.now().subtract(
            const Duration(days: 30),
          );

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
            throw Exception(AuthErrorMessages.userDataNotFound);
          }

          final userData = userDoc.data()!;

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

          return completeUserData;
        } catch (e) {
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
      // Firebase Auth로 로그인
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.toLowerCase(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception(AuthErrorMessages.loginFailed);
      }

      // 로그인 성공 시 병렬 처리로 완전한 데이터 반환
      final userData = await fetchCurrentUserWithTimerActivities();
      if (userData == null) {
        throw Exception(AuthErrorMessages.userDataNotFound);
      }

      return userData;
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
      // 유효성 검사
      AuthValidator.validateEmailFormat(email);
      AuthValidator.validateNicknameFormat(nickname);

      // 약관 동의 확인
      if (agreedTermsId == null || agreedTermsId.isEmpty) {
        throw Exception(AuthErrorMessages.termsNotAgreed);
      }

      // 닉네임 중복 확인
      final nicknameAvailable = await checkNicknameAvailability(nickname);
      if (!nicknameAvailable) {
        throw Exception(AuthErrorMessages.nicknameAlreadyInUse);
      }

      // Firebase Auth로 계정 생성
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.toLowerCase(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception(AuthErrorMessages.accountCreationFailed);
      }

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

      // 회원가입 시에도 완전한 데이터 반환 (타이머 활동은 비어있음)
      return {...userData, 'timerActivities': <Map<String, dynamic>>[]};
    }, params: {'email': email, 'nickname': nickname});
  }

  @override
  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    return ApiCallDecorator.wrap('FirebaseAuth.fetchCurrentUser', () async {
      // 최적화된 병렬 처리 메서드 사용
      return await fetchCurrentUserWithTimerActivities();
    });
  }

  @override
  Future<void> signOut() async {
    return ApiCallDecorator.wrap('FirebaseAuth.signOut', () async {
      await _auth.signOut();
    });
  }

  @override
  Future<bool> checkNicknameAvailability(String nickname) async {
    return ApiCallDecorator.wrap(
      'FirebaseAuth.checkNicknameAvailability',
      () async {
        // 유효성 검사
        AuthValidator.validateNicknameFormat(nickname);

        // Firestore에서 닉네임 중복 확인
        final query =
            await _usersCollection
                .where('nickname', isEqualTo: nickname)
                .limit(1)
                .get();

        return query.docs.isEmpty;
      },
      params: {'nickname': nickname},
    );
  }

  @override
  Future<bool> checkEmailAvailability(String email) async {
    return ApiCallDecorator.wrap(
      'FirebaseAuth.checkEmailAvailability',
      () async {
        // 유효성 검사
        AuthValidator.validateEmailFormat(email);

        // Firestore에서 직접 이메일 중복 확인
        final query =
            await _usersCollection
                .where('email', isEqualTo: email.toLowerCase())
                .limit(1)
                .get();

        return query.docs.isEmpty;
      },
      params: {'email': email},
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    return ApiCallDecorator.wrap(
      'FirebaseAuth.sendPasswordResetEmail',
      () async {
        // 유효성 검사
        AuthValidator.validateEmailFormat(email);

        await _auth.sendPasswordResetEmail(email: email.toLowerCase());
      },
      params: {'email': email},
    );
  }

  @override
  Future<void> deleteAccount(String email) async {
    return ApiCallDecorator.wrap('FirebaseAuth.deleteAccount', () async {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception(AuthErrorMessages.noLoggedInUser);
      }

      // Firestore에서 사용자 데이터 삭제
      await _usersCollection.doc(user.uid).delete();

      // Firebase Auth에서 계정 삭제
      await user.delete();
    }, params: {'email': email});
  }

  @override
  Future<Map<String, dynamic>> saveTermsAgreement(
    Map<String, dynamic> termsData,
  ) async {
    return ApiCallDecorator.wrap('FirebaseAuth.saveTermsAgreement', () async {
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

      return termsData;
    }, params: {'termsId': termsData['id']});
  }

  @override
  Future<Map<String, dynamic>> fetchTermsInfo() async {
    return ApiCallDecorator.wrap('FirebaseAuth.fetchTermsInfo', () async {
      return {
        'id': 'terms_${DateTime.now().millisecondsSinceEpoch}',
        'isAllAgreed': false,
        'isServiceTermsAgreed': false,
        'isPrivacyPolicyAgreed': false,
        'isMarketingAgreed': false,
        'agreedAt': Timestamp.now(),
      };
    });
  }

  @override
  Future<Map<String, dynamic>?> getTermsInfo(String termsId) async {
    return ApiCallDecorator.wrap('FirebaseAuth.getTermsInfo', () async {
      return {
        'id': termsId,
        'isAllAgreed': true,
        'isServiceTermsAgreed': true,
        'isPrivacyPolicyAgreed': true,
        'isMarketingAgreed': false,
        'agreedAt': Timestamp.now(),
      };
    }, params: {'termsId': termsId});
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTimerActivities(String userId) async {
    return ApiCallDecorator.wrap('FirebaseAuth.fetchTimerActivities', () async {
      // 이미 fetchCurrentUserWithTimerActivities에서 포함되므로
      // 별도 호출 시에만 동작하도록 유지
      final query =
          await _usersCollection
              .doc(userId)
              .collection('timerActivities')
              .orderBy('timestamp', descending: true)
              .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();
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
        // Firebase: users/{userId}/timerActivities 서브컬렉션에 저장
        final activityRef = _usersCollection
            .doc(userId)
            .collection('timerActivities');

        // ID가 있으면 해당 문서 업데이트, 없으면 자동 생성
        final activityId = activityData['id'] as String?;

        if (activityId != null) {
          await activityRef.doc(activityId).set({
            ...activityData,
            'timestamp':
                activityData['timestamp'] is DateTime
                    ? Timestamp.fromDate(activityData['timestamp'] as DateTime)
                    : activityData['timestamp'],
          });
        } else {
          await activityRef.add({
            ...activityData,
            'timestamp':
                activityData['timestamp'] is DateTime
                    ? Timestamp.fromDate(activityData['timestamp'] as DateTime)
                    : activityData['timestamp'],
          });
        }
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
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception(AuthErrorMessages.noLoggedInUser);
      }

      // 닉네임 유효성 검사
      AuthValidator.validateNicknameFormat(nickname);

      // 현재 닉네임과 다른 경우에만 중복 확인
      final currentUserDoc = await _usersCollection.doc(user.uid).get();
      final currentNickname = currentUserDoc.data()?['nickname'] as String?;

      if (currentNickname != nickname) {
        final nicknameAvailable = await checkNicknameAvailability(nickname);
        if (!nicknameAvailable) {
          throw Exception(AuthErrorMessages.nicknameAlreadyInUse);
        }
      }

      // Firestore에 사용자 정보 업데이트
      final updateData = {
        'nickname': nickname,
        'description': description ?? '',
        'position': position ?? '',
        'skills': skills ?? '',
      };

      await _usersCollection.doc(user.uid).update(updateData);

      // 업데이트된 완전한 사용자 정보 반환 (병렬 처리 활용)
      final updatedUserData = await fetchCurrentUserWithTimerActivities();
      if (updatedUserData == null) {
        throw Exception(AuthErrorMessages.userDataNotFound);
      }

      return updatedUserData;
    }, params: {'nickname': nickname});
  }

  @override
  Future<Map<String, dynamic>> updateUserImage(String imagePath) async {
    return ApiCallDecorator.wrap('FirebaseAuth.updateUserImage', () async {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception(AuthErrorMessages.noLoggedInUser);
      }

      // Firebase Storage에 이미지 업로드 로직은 현재 미구현
      // 임시로 로컬 파일 경로를 저장
      await _usersCollection.doc(user.uid).update({'image': imagePath});

      // 업데이트된 완전한 사용자 정보 반환 (병렬 처리 활용)
      final updatedUserData = await fetchCurrentUserWithTimerActivities();
      if (updatedUserData == null) {
        throw Exception(AuthErrorMessages.userDataNotFound);
      }

      return updatedUserData;
    }, params: {'imagePath': imagePath});
  }

  @override
  Stream<Map<String, dynamic>?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;

      try {
        // 사용자 정보와 타이머 활동 조회
        return await fetchCurrentUserWithTimerActivities();
      } catch (e) {
        debugPrint('Firebase auth state stream error: $e');
        return null;
      }
    });
  }

  // @override
  // Future<AuthState> getCurrentAuthState() async {
  //   return ApiCallDecorator.wrap(
  //     'AuthRepository.getCurrentAuthState',
  //         () async {
  //       try {
  //         final result = await getCurrentUser();
  //         switch (result) {
  //           case Success(data: final member):
  //             return AuthState.authenticated(member);
  //           case Error():
  //             return const AuthState.unauthenticated();
  //         }
  //       } catch (e) {
  //         debugPrint('Get current auth state error: $e');
  //         return const AuthState.unauthenticated();
  //       }
  //     },
  //   );
  // }
}
