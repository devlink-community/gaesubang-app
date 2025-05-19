// lib/auth/core/utils/auth_exception_mapper.dart
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/result/result.dart';
import 'auth_error_messages.dart';

class AuthExceptionMapper {
  AuthExceptionMapper._(); // 인스턴스화 방지

  static Failure mapAuthException(Object error, StackTrace stackTrace) {
    // Firebase Auth 예외 처리
    if (error is FirebaseAuthException) {
      return _mapFirebaseAuthException(error, stackTrace);
    }

    // 일반 Exception 처리 (기존 Mock에서 사용하던 것들)
    if (error is Exception) {
      final message = error.toString().replaceFirst('Exception: ', '');
      return Failure(
        FailureType.validation,
        message,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 알 수 없는 에러
    return Failure(
      FailureType.unknown,
      AuthErrorMessages.unknown,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  /// Firebase Auth 예외를 Failure로 변환
  static Failure _mapFirebaseAuthException(
    FirebaseAuthException error,
    StackTrace stackTrace,
  ) {
    late String message;
    late FailureType type;

    switch (error.code) {
      // 로그인 관련
      case 'user-not-found':
        message = AuthErrorMessages.accountNotFound;
        type = FailureType.unauthorized;
        break;
      case 'wrong-password':
        message = AuthErrorMessages.invalidCredentials;
        type = FailureType.unauthorized;
        break;
      case 'invalid-email':
        message = AuthErrorMessages.invalidEmail;
        type = FailureType.validation;
        break;
      case 'user-disabled':
        message = AuthErrorMessages.accountDisabled;
        type = FailureType.unauthorized;
        break;
      case 'too-many-requests':
        message = AuthErrorMessages.tooManyRequests;
        type = FailureType.network;
        break;

      // 회원가입 관련
      case 'weak-password':
        message = AuthErrorMessages.weakPassword;
        type = FailureType.validation;
        break;
      case 'email-already-in-use':
        message = AuthErrorMessages.emailAlreadyInUse;
        type = FailureType.validation;
        break;

      // 계정 삭제 관련
      case 'requires-recent-login':
        message = AuthErrorMessages.requiresRecentLogin;
        type = FailureType.unauthorized;
        break;

      // 네트워크 관련
      case 'network-request-failed':
        message = AuthErrorMessages.networkError;
        type = FailureType.network;
        break;

      // 기타
      default:
        message = AuthErrorMessages.unknown;
        type = FailureType.unknown;
        break;
    }

    return Failure(type, message, cause: error, stackTrace: stackTrace);
  }

  /// 공통 유효성 검사 및 Exception 생성
  static void validateNickname(String nickname) {
    if (nickname.length < 2) {
      throw Exception(AuthErrorMessages.nicknameTooShort);
    }
    if (nickname.length > 10) {
      throw Exception(AuthErrorMessages.nicknameTooLong);
    }
    if (!RegExp(r'^[a-zA-Z0-9가-힣]+$').hasMatch(nickname)) {
      throw Exception(AuthErrorMessages.nicknameInvalidCharacters);
    }
  }

  static void validateEmail(String email) {
    if (!email.contains('@') || !email.contains('.')) {
      throw Exception(AuthErrorMessages.invalidEmail);
    }
  }

  static void validateRequiredTerms({
    required bool isServiceTermsAgreed,
    required bool isPrivacyPolicyAgreed,
  }) {
    if (!isServiceTermsAgreed || !isPrivacyPolicyAgreed) {
      throw Exception(AuthErrorMessages.termsNotAgreed);
    }
  }
}
