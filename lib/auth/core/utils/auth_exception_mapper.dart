// lib/auth/core/utils/auth_exception_mapper.dart

import 'dart:async';
import 'dart:io';

import 'package:devlink_mobile_app/auth/core/utils/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:flutter/foundation.dart';

/// 인증 관련 예외를 세밀하게 Failure로 변환하는 유틸리티 클래스
class AuthExceptionMapper {
  AuthExceptionMapper._(); // 인스턴스화 방지

  /// 인증 관련 예외를 Failure 객체로 매핑하는 함수
  static Failure mapAuthException(Object error, StackTrace stackTrace) {
    // 1. 디버그 모드에서 콘솔에 에러 로깅
    debugPrint('⚠️ 인증 예외 발생: $error');
    debugPrint('🧾 스택 트레이스: $stackTrace');

    // 2. 인증 관련 예외 타입 체크 및 변환
    if (error is TimeoutException) {
      return Failure(
        FailureType.timeout,
        AuthErrorMessages.timeout,
        cause: error,
        stackTrace: stackTrace,
      );
    } else if (error is SocketException || error.toString().contains('SocketException')) {
      return Failure(
        FailureType.network,
        AuthErrorMessages.networkError,
        cause: error,
        stackTrace: stackTrace,
      );
    } else if (error is FormatException) {
      return Failure(
        FailureType.parsing,
        AuthErrorMessages.operationFailed,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 3. 로그인/가입 관련 예외 메시지 확인 (문자열 기반)
    final String errorMsg = error.toString().toLowerCase();

    // 이메일/비밀번호 불일치 검사
    if (errorMsg.contains('이메일 또는 비밀번호가 일치하지 않') ||
        errorMsg.contains('incorrect') && errorMsg.contains('password')) {
      return Failure(
        FailureType.unauthorized,
        AuthErrorMessages.invalidCredentials,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 이메일 중복 검사
    else if (errorMsg.contains('이미 사용 중인 이메일') ||
        errorMsg.contains('email already in use')) {
      return Failure(
        FailureType.validation,
        AuthErrorMessages.emailAlreadyInUse,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 닉네임 중복 검사
    else if (errorMsg.contains('이미 사용 중인 닉네임') ||
        errorMsg.contains('nickname already')) {
      return Failure(
        FailureType.validation,
        AuthErrorMessages.nicknameAlreadyInUse,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 닉네임 형식 검사
    else if (errorMsg.contains('닉네임은 한글') ||
        errorMsg.contains('nickname should')) {
      return Failure(
        FailureType.validation,
        AuthErrorMessages.nicknameInvalidCharacters,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 약관 동의 검사
    else if (errorMsg.contains('약관') && errorMsg.contains('동의')) {
      return Failure(
        FailureType.validation,
        AuthErrorMessages.termsNotAgreed,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 계정 미등록 검사
    else if (errorMsg.contains('등록되지 않은') && errorMsg.contains('이메일')) {
      return Failure(
        FailureType.validation,
        AuthErrorMessages.emailNotRegistered,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 서버 오류 검사
    else if (errorMsg.contains('server') && errorMsg.contains('error')) {
      return Failure(
        FailureType.server,
        AuthErrorMessages.serverError,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 4. 예외 유형을 파악할 수 없는 경우 기본 메시지 반환
    return Failure(
      FailureType.unknown,
      AuthErrorMessages.unknown,
      cause: error,
      stackTrace: stackTrace,
    );
  }
}