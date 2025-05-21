// lib/core/utils/auth_validator.dart

import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';

class AuthValidator {
  const AuthValidator._();

  /// 이메일 유효성 검사
  static String? validateEmail(String email) {
    if (email.isEmpty) {
      return AuthErrorMessages.emailRequired;
    }

    // 이메일 형식 유효성 검사는 대소문자 구분 없이 수행
    // 실제 이메일은 대소문자를 구분하지 않으므로 형식 검증만 수행하고
    // 실제 DB 저장/조회 시 소문자 변환은 DataSource에서 처리
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      return AuthErrorMessages.invalidEmail;
    }

    return null; // 유효한 경우
  }

  /// 닉네임 유효성 검사
  static String? validateNickname(String nickname) {
    if (nickname.isEmpty) {
      return AuthErrorMessages.nicknameRequired;
    }

    if (nickname.length < 2) {
      return AuthErrorMessages.nicknameTooShort;
    }

    if (nickname.length > 10) {
      return AuthErrorMessages.nicknameTooLong;
    }

    // 특수문자 제한
    if (!RegExp(r'^[a-zA-Z0-9가-힣]+$').hasMatch(nickname)) {
      return AuthErrorMessages.nicknameInvalidFormat;
    }

    return null; // 유효한 경우
  }

  /// 비밀번호 유효성 검사
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return AuthErrorMessages.passwordRequired;
    }

    if (password.length < 8) {
      return AuthErrorMessages.passwordTooShort;
    }

    // 복잡성 요구사항 검증
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!(hasUppercase && hasLowercase && hasDigit && hasSpecialChar)) {
      return AuthErrorMessages.passwordComplexity;
    }

    return null; // 유효한 경우
  }

  /// 비밀번호 확인 유효성 검사
  static String? validatePasswordConfirm(
    String password,
    String passwordConfirm,
  ) {
    if (passwordConfirm.isEmpty) {
      return AuthErrorMessages.passwordConfirmRequired;
    }

    if (password != passwordConfirm) {
      return AuthErrorMessages.passwordMismatch;
    }

    return null; // 유효한 경우
  }

  /// 약관 동의 유효성 검사
  static String? validateTermsAgreement(bool agreed) {
    if (!agreed) {
      return AuthErrorMessages.termsRequired;
    }

    return null; // 유효한 경우
  }

  /// 이메일 형식 검증 (Exception throw 버전) - DataSource에서 사용
  static void validateEmailFormat(String email) {
    final error = validateEmail(email);
    if (error != null) {
      throw Exception(error);
    }
  }

  /// 닉네임 형식 검증 (Exception throw 버전) - DataSource에서 사용
  static void validateNicknameFormat(String nickname) {
    final error = validateNickname(nickname);
    if (error != null) {
      throw Exception(error);
    }
  }

  /// 필수 약관 동의 검증 (Exception throw 버전) - DataSource에서 사용
  static void validateRequiredTerms({
    required bool isServiceTermsAgreed,
    required bool isPrivacyPolicyAgreed,
  }) {
    if (!isServiceTermsAgreed || !isPrivacyPolicyAgreed) {
      throw Exception(AuthErrorMessages.termsNotAgreed);
    }
  }
}
