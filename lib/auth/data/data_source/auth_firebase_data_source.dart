import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/auth_validator.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
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
       _storage = storage ?? FirebaseStorage.instance;

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

      // 🔥 닉네임 중복 확인 (Firestore에서만 확인 가능)
      final nicknameAvailable = await checkNicknameAvailability(nickname);
      if (!nicknameAvailable) {
        throw Exception(AuthErrorMessages.nicknameAlreadyInUse);
      }

      // 🔥 이메일 중복 확인은 Firestore에서만 가능 (Firebase Auth는 보안상 확인 불가)
      final emailAvailableInFirestore = await _checkEmailInFirestore(email);
      if (!emailAvailableInFirestore) {
        throw Exception(AuthErrorMessages.emailAlreadyInUse);
      }

      UserCredential? credential;
      User? user;

      try {
        // 🔥 Firebase Auth로 계정 생성 시도 (이때 실제 중복이 감지됨)
        credential = await _auth.createUserWithEmailAndPassword(
          email: email.toLowerCase(),
          password: password,
        );

        user = credential.user;
        if (user == null) {
          throw Exception(AuthErrorMessages.accountCreationFailed);
        }

        debugPrint('✅ Firebase Auth 계정 생성 성공: ${user.uid}');
      } catch (e) {
        debugPrint('❌ Firebase Auth 계정 생성 실패: $e');

        // Firebase Auth 에러 코드별 처리
        if (e is FirebaseAuthException) {
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
        // Firebase Auth 프로필 정보 설정 (displayName)
        await user.updateDisplayName(nickname);

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

        debugPrint('✅ Firestore 사용자 데이터 저장 완료');

        // 회원가입 시에도 완전한 데이터 반환 (타이머 활동은 비어있음)
        return {...userData, 'timerActivities': <Map<String, dynamic>>[]};
      } catch (e) {
        debugPrint('❌ Firestore 저장 실패, Firebase Auth 계정 삭제: $e');

        // Firestore 저장 실패 시 생성된 Firebase Auth 계정을 삭제
        try {
          await user.delete();
          debugPrint('✅ Firebase Auth 계정 롤백 완료');
        } catch (deleteError) {
          debugPrint('⚠️ Firebase Auth 계정 삭제 실패: $deleteError');
        }

        throw Exception('사용자 정보 저장에 실패했습니다: $e');
      }
    }, params: {'email': email, 'nickname': nickname});
  }

  /// Firestore에서만 이메일 중복 확인 (Firebase Auth 확인은 보안상 불가능)
  Future<bool> _checkEmailInFirestore(String email) async {
    try {
      final normalizedEmail = email.toLowerCase();

      final query =
          await _usersCollection
              .where('email', isEqualTo: normalizedEmail)
              .limit(1)
              .get();

      final isAvailable = query.docs.isEmpty;

      debugPrint(
        'Firestore 이메일 중복 확인: $normalizedEmail -> ${isAvailable ? "사용가능" : "사용불가"}',
      );

      return isAvailable;
    } catch (e) {
      debugPrint('Firestore 이메일 확인 중 오류: $e');
      // 오류 발생 시 안전하게 사용 불가로 처리
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    return ApiCallDecorator.wrap('FirebaseAuth.fetchCurrentUser', () async {
      final user = _auth.currentUser;
      if (user == null) return null;

      // 재시도 로직이 포함된 메서드 사용
      return await _fetchUserDataWithRetry(user.uid);
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

        // 🔥 Firebase Auth에서는 보안상 이메일 중복 확인이 제한됨
        // Firestore에서만 확인 가능하며, 실제 중복은 createUser 시점에서 감지됨
        return await _checkEmailInFirestore(email);
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

      // Firebase Auth 프로필 변경이 되었음을 확실히 하기 위해 재인증 트리거
      // 이는 authStateChanges 이벤트를 강제로 발생시킵니다
      await user.reload();

      debugPrint('Firebase 프로필 정보 업데이트 완료: $nickname');

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

      try {
        debugPrint('🔄 프로필 이미지 업로드 시작: $imagePath');

        // 1. 이미지 파일 검증 (이미 UseCase에서 압축된 파일을 받음)
        final File imageFile = File(imagePath);
        if (!await imageFile.exists()) {
          throw Exception('이미지 파일을 찾을 수 없습니다');
        }

        // 2. 이미지 바이트 읽기 (이미 압축된 상태)
        final Uint8List imageBytes = await imageFile.readAsBytes();

        debugPrint('📤 업로드할 이미지 크기: ${imageBytes.length ~/ 1024}KB');

        // 3. Firebase Storage에 업로드
        final String fileName =
            'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String storagePath = 'users/${user.uid}/$fileName';

        final Reference storageRef = _storage.ref().child(storagePath);

        // 기존 프로필 이미지가 있다면 삭제
        await _deleteExistingProfileImage(user.uid);

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

        debugPrint('✅ Firebase Storage 이미지 업로드 완료: $downloadUrl');

        // 5. Firebase Auth 프로필 이미지 업데이트 (photoURL)
        await user.updatePhotoURL(downloadUrl);

        // 6. Firestore에 이미지 URL 업데이트
        await _usersCollection.doc(user.uid).update({'image': downloadUrl});

        // 7. Firebase Auth 프로필 변경이 되었음을 확실히 하기 위해 재인증 트리거
        await user.reload();

        debugPrint('✅ Firebase 프로필 이미지 업데이트 완료: $downloadUrl');

        // 8. 업데이트된 완전한 사용자 정보 반환
        final updatedUserData = await fetchCurrentUserWithTimerActivities();
        if (updatedUserData == null) {
          throw Exception(AuthErrorMessages.userDataNotFound);
        }

        return updatedUserData;
      } catch (e, stackTrace) {
        debugPrint('❌ 프로필 이미지 업데이트 실패: $e');
        debugPrint('StackTrace: $stackTrace');

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
      final currentUserDoc = await _usersCollection.doc(userId).get();
      final currentImageUrl = currentUserDoc.data()?['image'] as String?;

      if (currentImageUrl != null &&
          currentImageUrl.isNotEmpty &&
          currentImageUrl.contains('firebase')) {
        final Reference oldImageRef = _storage.refFromURL(currentImageUrl);
        await oldImageRef.delete();
        debugPrint('✅ 기존 프로필 이미지 삭제 완료');
      }
    } catch (e) {
      debugPrint('⚠️  기존 이미지 삭제 실패 (무시함): $e');
      // 삭제 실패는 치명적이지 않으므로 예외를 던지지 않음
    }
  }

  // 인증 상태 변화 스트림 (Firebase userChanges() 사용)
  @override
  Stream<Map<String, dynamic>?> get authStateChanges {
    // Firebase Auth의 userChanges() 사용 - 프로필 정보 변경도 감지
    return _auth.userChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        debugPrint('Firebase 인증 상태 변경: 로그아웃됨');
        return null;
      }

      debugPrint('Firebase 인증 상태 변경: 로그인됨 또는 프로필 변경 (${firebaseUser.uid})');
      debugPrint(
        'Firebase 사용자 프로필: displayName=${firebaseUser.displayName}, photoURL=${firebaseUser.photoURL}',
      );

      // 재시도 로직이 포함된 사용자 정보 가져오기
      return await _fetchUserDataWithRetry(firebaseUser.uid);
    }).distinct(); // 중복 이벤트 방지
  }

  /// 재시도 로직이 포함된 사용자 데이터 가져오기
  Future<Map<String, dynamic>?> _fetchUserDataWithRetry(
    String uid, {
    int maxRetries = 5,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // fetchCurrentUserWithTimerActivities 호출
        final userData = await fetchCurrentUserWithTimerActivities();
        if (userData != null) {
          debugPrint('✅ 인증 상태 스트림: 사용자 데이터 조회 성공 (시도: $attempt/$maxRetries)');
          return userData;
        }
      } catch (e) {
        debugPrint('⚠️ 인증 상태 스트림 시도 $attempt/$maxRetries 실패: $e');

        // 마지막 시도가 아니라면 재시도
        if (attempt < maxRetries) {
          // 점진적으로 증가하는 대기 시간 (500ms, 1s, 1.5s, 2s, 2.5s)
          final delayMs = 500 * attempt;
          debugPrint('⏳ ${delayMs}ms 후 재시도...');
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }

        // 최대 재시도 횟수 초과
        debugPrint('❌ 인증 상태 스트림: 최대 재시도 횟수 초과 ($maxRetries회)');
        debugPrint('❌ 최종 오류: $e');
      }
    }

    // 모든 재시도가 실패한 경우 null 반환 (unauthenticated 상태로 처리)
    return null;
  }

  // 현재 인증 상태 확인 (추가)
  @override
  Future<Map<String, dynamic>?> getCurrentAuthState() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    // 재시도 로직이 포함된 메서드 사용
    return await _fetchUserDataWithRetry(user.uid);
  }

  @override
  Future<UserDto> fetchUserProfile(String userId) async {
    return ApiCallDecorator.wrap('AuthFirebase.fetchUserProfile', () async {
      try {
        // Firestore에서 특정 사용자 문서 조회
        final docSnapshot = await _usersCollection.doc(userId).get();

        if (!docSnapshot.exists) {
          throw Exception('사용자를 찾을 수 없습니다');
        }

        final userData = docSnapshot.data()!;
        userData['uid'] = docSnapshot.id; // 문서 ID를 uid로 설정

        return UserDto.fromJson(userData);
      } catch (e) {
        print('사용자 프로필 조회 오류: $e');
        throw Exception('사용자 프로필을 불러오는데 실패했습니다');
      }
    }, params: {'userId': userId});
  }

  @override
  Future<void> updateUserStats(
    String userId,
    Map<String, dynamic> statsData,
  ) async {
    return ApiCallDecorator.wrap(
      'FirebaseAuth.updateUserStats',
      () async {
        try {
          debugPrint('🔄 Firebase 사용자 통계 업데이트 시작: $userId');

          // Firestore User 문서 업데이트
          await _usersCollection.doc(userId).update(statsData);

          debugPrint('✅ Firebase 사용자 통계 업데이트 완료');
        } catch (e) {
          debugPrint('❌ Firebase 사용자 통계 업데이트 실패: $e');
          throw Exception('사용자 통계 업데이트에 실패했습니다: $e');
        }
      },
      params: {'userId': userId, 'statsData': statsData},
    );
  }
}
