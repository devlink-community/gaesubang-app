// lib/auth/data/data_source/auth_firebase_data_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/auth_error_messages.dart'
    show AuthErrorMessages;
import 'package:devlink_mobile_app/core/utils/auth_exception_mapper.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  Future<Map<String, dynamic>> fetchLogin({
    required String email,
    required String password,
  }) async {
    // Firebase Auth로 로그인
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.toLowerCase(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception(AuthErrorMessages.loginFailed);
    }

    // Firestore에서 완전한 사용자 정보 가져오기
    final userDoc = await _usersCollection.doc(user.uid).get();

    if (!userDoc.exists) {
      throw Exception(AuthErrorMessages.userDataNotFound);
    }

    final userData = userDoc.data()!;

    // 완전한 사용자 정보 반환 (Member 모델에 필요한 모든 필드 포함)
    return {
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
    };
  }

  @override
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String nickname,
    String? agreedTermsId,
  }) async {
    // 유효성 검사
    AuthExceptionMapper.validateEmail(email);
    AuthExceptionMapper.validateNickname(nickname);

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

    return userData;
  }

  @override
  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    // Firestore에서 완전한 사용자 정보 가져오기
    final userDoc = await _usersCollection.doc(user.uid).get();

    if (!userDoc.exists) {
      return null;
    }

    final userData = userDoc.data()!;

    // 완전한 사용자 정보 반환
    return {
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
    };
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<bool> checkNicknameAvailability(String nickname) async {
    // 유효성 검사
    AuthExceptionMapper.validateNickname(nickname);

    // Firestore에서 닉네임 중복 확인
    final query =
        await _usersCollection
            .where('nickname', isEqualTo: nickname)
            .limit(1)
            .get();

    return query.docs.isEmpty;
  }

  @override
  Future<bool> checkEmailAvailability(String email) async {
    // 유효성 검사
    AuthExceptionMapper.validateEmail(email);

    // Firestore에서 직접 이메일 중복 확인
    final query =
        await _usersCollection
            .where('email', isEqualTo: email.toLowerCase())
            .limit(1)
            .get();

    return query.docs.isEmpty;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // 유효성 검사
    AuthExceptionMapper.validateEmail(email);

    await _auth.sendPasswordResetEmail(email: email.toLowerCase());
  }

  @override
  Future<void> deleteAccount(String email) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception(AuthErrorMessages.noLoggedInUser);
    }

    // Firestore에서 사용자 데이터 삭제
    await _usersCollection.doc(user.uid).delete();

    // Firebase Auth에서 계정 삭제
    await user.delete();
  }

  @override
  Future<Map<String, dynamic>> saveTermsAgreement(
    Map<String, dynamic> termsData,
  ) async {
    // 필수 약관 동의 여부 확인
    final isServiceTermsAgreed =
        termsData['isServiceTermsAgreed'] as bool? ?? false;
    final isPrivacyPolicyAgreed =
        termsData['isPrivacyPolicyAgreed'] as bool? ?? false;

    AuthExceptionMapper.validateRequiredTerms(
      isServiceTermsAgreed: isServiceTermsAgreed,
      isPrivacyPolicyAgreed: isPrivacyPolicyAgreed,
    );

    // 타임스탬프 추가
    termsData['agreedAt'] = Timestamp.now();
    termsData['id'] = 'terms_${DateTime.now().millisecondsSinceEpoch}';

    return termsData;
  }

  @override
  Future<Map<String, dynamic>> fetchTermsInfo() async {
    return {
      'id': 'terms_${DateTime.now().millisecondsSinceEpoch}',
      'isAllAgreed': false,
      'isServiceTermsAgreed': false,
      'isPrivacyPolicyAgreed': false,
      'isMarketingAgreed': false,
      'agreedAt': Timestamp.now(),
    };
  }

  @override
  Future<Map<String, dynamic>?> getTermsInfo(String termsId) async {
    return {
      'id': termsId,
      'isAllAgreed': true,
      'isServiceTermsAgreed': true,
      'isPrivacyPolicyAgreed': true,
      'isMarketingAgreed': false,
      'agreedAt': Timestamp.now(),
    };
  }
}
