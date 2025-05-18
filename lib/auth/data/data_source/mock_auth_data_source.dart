// lib/auth/data/data_source/mock_auth_data_source.dart
import 'dart:async';

import '../dto/profile_dto.dart';
import '../dto/user_dto.dart';
import 'auth_data_source.dart';
import 'user_storage.dart';

class MockAuthDataSource implements AuthDataSource {
  final _storage = UserStorage.instance;

  @override
  Future<Map<String, dynamic>> fetchLogin({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // 이메일을 소문자로 변환
    final lowercaseEmail = email.toLowerCase();

    final user = _storage.getUserByEmail(lowercaseEmail);

    // 사용자 존재 확인 및 비밀번호 검증
    if (user != null && _validatePassword(lowercaseEmail, password)) {
      _storage.login(user.id!);
      return user.toJson();
    } else {
      // 명확한 에러 메시지 사용
      if (user == null) {
        throw Exception('등록되지 않은 이메일입니다');
      } else {
        throw Exception('이메일 또는 비밀번호가 일치하지 않습니다');
      }
    }
  }

  @override
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String nickname,
    String? agreedTermsId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // 이메일을 소문자로 변환
    final lowercaseEmail = email.toLowerCase();

    // 약관 동의 확인
    if (agreedTermsId == null || agreedTermsId.isEmpty) {
      throw Exception('필수 약관에 동의해야 합니다');
    }

    // 중복 체크
    if (!_storage.isEmailAvailable(lowercaseEmail)) {
      throw Exception('이미 사용 중인 이메일입니다');
    }

    if (!_storage.isNicknameAvailable(nickname)) {
      throw Exception('이미 사용 중인 닉네임입니다');
    }

    // 닉네임 유효성 검사
    if (nickname.length < 2) {
      throw Exception('닉네임은 2자 이상이어야 합니다');
    }

    if (nickname.length > 10) {
      throw Exception('닉네임은 10자 이하여야 합니다');
    }

    if (!RegExp(r'^[a-zA-Z0-9가-힣]+$').hasMatch(nickname)) {
      throw Exception('닉네임은 한글, 영문, 숫자만 사용 가능합니다');
    }

    // 새 사용자 생성
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final userDto = UserDto(
      id: userId,
      email: lowercaseEmail, // 소문자로 변환된 이메일 저장
      nickname: nickname,
      uid: 'uid_$userId',
      agreedTermsId: agreedTermsId,
    );

    final profileDto = ProfileDto(
      userId: userId,
      image: '',
      onAir: false,
    );

    // 비밀번호는 별도 저장 (여기서는 간단히 구현)
    _storage.addUser(userDto, profileDto, password, agreedTermsId: agreedTermsId);

    return userDto.toJson();
  }

  @override
  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final currentUser = _storage.currentUser;
    return currentUser?.toJson();
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _storage.logout();
  }

  @override
  Future<bool> checkNicknameAvailability(String nickname) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // 닉네임 유효성 검사 추가
    if (nickname.length < 2) {
      throw Exception('닉네임은 2자 이상이어야 합니다');
    }

    if (nickname.length > 10) {
      throw Exception('닉네임은 10자 이하여야 합니다');
    }

    if (!RegExp(r'^[a-zA-Z0-9가-힣]+$').hasMatch(nickname)) {
      throw Exception('닉네임은 한글, 영문, 숫자만 사용 가능합니다');
    }

    return _storage.isNicknameAvailable(nickname);
  }

  @override
  Future<bool> checkEmailAvailability(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // 이메일 형식 유효성 검사
    if (!email.contains('@') || !email.contains('.')) {
      throw Exception('유효하지 않은 이메일 형식입니다');
    }

    // 이메일을 소문자로 변환하여 확인
    return _storage.isEmailAvailable(email.toLowerCase());
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // 이메일 형식 확인
    if (!email.contains('@') || !email.contains('.')) {
      throw Exception('유효하지 않은 이메일 형식입니다');
    }

    // 이메일을 소문자로 변환
    final lowercaseEmail = email.toLowerCase();

    // 가입된 이메일인지 확인
    final user = _storage.getUserByEmail(lowercaseEmail);
    if (user == null) {
      throw Exception('등록되지 않은 이메일입니다');
    }

    // 성공 시 void 반환 (실제로는 이메일 전송)
  }

  @override
  Future<void> deleteAccount(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // 이메일을 소문자로 변환
    final lowercaseEmail = email.toLowerCase();

    final user = _storage.getUserByEmail(lowercaseEmail);
    if (user == null) {
      throw Exception('사용자를 찾을 수 없습니다');
    }

    // 현재 로그인된 사용자인지 확인
    if (_storage.currentUserId != user.id) {
      throw Exception('로그인된 사용자만 계정을 삭제할 수 있습니다');
    }

    _storage.deleteUser(lowercaseEmail);
  }

  @override
  Future<Map<String, dynamic>> saveTermsAgreement(Map<String, dynamic> termsData) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // 필수 약관 동의 여부 확인
    final isServiceTermsAgreed = termsData['isServiceTermsAgreed'] as bool? ?? false;
    final isPrivacyPolicyAgreed = termsData['isPrivacyPolicyAgreed'] as bool? ?? false;

    if (!isServiceTermsAgreed || !isPrivacyPolicyAgreed) {
      throw Exception('필수 약관에 동의해야 합니다');
    }

    return _storage.saveTermsAgreement(termsData);
  }

  @override
  Future<Map<String, dynamic>> fetchTermsInfo() async {
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      // 기본 약관 정보 반환
      return {
        'id': 'terms_${DateTime.now().millisecondsSinceEpoch}',
        'isAllAgreed': false,
        'isServiceTermsAgreed': false,
        'isPrivacyPolicyAgreed': false,
        'isMarketingAgreed': false,
        'createdAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('약관 정보를 불러오는데 실패했습니다');
    }
  }

  @override
  Future<Map<String, dynamic>?> getTermsInfo(String termsId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final termsInfo = _storage.getTermsInfo(termsId);
      if (termsInfo == null) {
        throw Exception('약관 정보를 찾을 수 없습니다');
      }
      return termsInfo;
    } catch (e) {
      throw Exception('약관 정보를 불러오는데 실패했습니다');
    }
  }

  // 비밀번호 검증 메서드
  bool _validatePassword(String email, String password) {
    // UserStorage에서 실제 비밀번호 검증
    // 이메일을 소문자로 변환하여 검증
    return _storage.validatePassword(email.toLowerCase(), password);
  }
}