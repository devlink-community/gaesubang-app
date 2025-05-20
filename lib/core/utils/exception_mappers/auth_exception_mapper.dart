// lib/core/utils/auth_exception_mapper.dart

import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';

class AuthExceptionMapper {
  const AuthExceptionMapper._();

  /// Exception을 Failure로 매핑하는 유틸
  static Failure mapAuthException(Object error, StackTrace stackTrace) {
    final errorMessage = error.toString();

    // Firebase Auth 에러 처리
    if (errorMessage.contains('user-not-found')) {
      return Failure(
        FailureType.unauthorized,
        AuthErrorMessages.userNotFound,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (errorMessage.contains('wrong-password')) {
      return Failure(
        FailureType.unauthorized,
        AuthErrorMessages.wrongPassword,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (errorMessage.contains('email-already-in-use')) {
      return Failure(
        FailureType.validation,
        AuthErrorMessages.emailAlreadyInUse,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (errorMessage.contains('weak-password')) {
      return Failure(
        FailureType.validation,
        AuthErrorMessages.weakPassword,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (errorMessage.contains('invalid-email')) {
      return Failure(
        FailureType.validation,
        AuthErrorMessages.invalidEmail,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 네트워크 관련 에러
    if (errorMessage.contains('network-request-failed')) {
      return Failure(
        FailureType.network,
        AuthErrorMessages.networkError,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 타임아웃 에러
    if (errorMessage.contains('timeout')) {
      return Failure(
        FailureType.timeout,
        AuthErrorMessages.timeoutError,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 일반적인 Exception 메시지 처리
    if (errorMessage.startsWith('Exception: ')) {
      final message = errorMessage.substring('Exception: '.length);
      return Failure(
        FailureType.validation,
        message,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 기타 에러
    return Failure(
      FailureType.unknown,
      AuthErrorMessages.unknownError,
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
