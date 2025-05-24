// lib/core/utils/exception_mappers/banner_exception_mapper.dart

import '../../result/result.dart';

/// 배너 관련 예외를 Failure 객체로 변환하는 매퍼
class BannerExceptionMapper {
  const BannerExceptionMapper._(); // 인스턴스화 방지

  /// 배너 관련 예외를 Failure로 매핑
  static Failure mapBannerException(Object error, StackTrace stackTrace) {
    final errorMessage = error.toString().toLowerCase();

    // 네트워크 관련 에러
    if (_isNetworkError(errorMessage)) {
      return Failure(
        FailureType.network,
        '네트워크 연결을 확인해주세요',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 타임아웃 에러
    if (_isTimeoutError(errorMessage)) {
      return Failure(
        FailureType.timeout,
        '배너 조회 요청 시간이 초과되었습니다',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 서버 에러
    if (_isServerError(errorMessage)) {
      return Failure(
        FailureType.server,
        '배너 서버에 일시적인 문제가 발생했습니다',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 권한 관련 에러
    if (_isUnauthorizedError(errorMessage)) {
      return Failure(
        FailureType.unauthorized,
        '배너 조회 권한이 없습니다',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 데이터 파싱 에러
    if (_isParsingError(errorMessage)) {
      return Failure(
        FailureType.parsing,
        '배너 데이터 형식에 오류가 있습니다',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 배너 찾을 수 없음
    if (_isNotFoundError(errorMessage)) {
      return Failure(
        FailureType.server,
        '요청한 배너를 찾을 수 없습니다',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 기타 예외
    return Failure(
      FailureType.unknown,
      '배너 조회 중 알 수 없는 오류가 발생했습니다',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  // 네트워크 에러 판별
  static bool _isNetworkError(String errorMessage) {
    return errorMessage.contains('socketexception') ||
           errorMessage.contains('network') ||
           errorMessage.contains('connection') ||
           errorMessage.contains('host') ||
           errorMessage.contains('dns');
  }

  // 타임아웃 에러 판별
  static bool _isTimeoutError(String errorMessage) {
    return errorMessage.contains('timeout') ||
           errorMessage.contains('timeoutexception');
  }

  // 서버 에러 판별 (HTTP 5xx)
  static bool _isServerError(String errorMessage) {
    return errorMessage.contains('500') ||
           errorMessage.contains('502') ||
           errorMessage.contains('503') ||
           errorMessage.contains('504') ||
           errorMessage.contains('server error') ||
           errorMessage.contains('internal server');
  }

  // 권한 에러 판별 (HTTP 401, 403)
  static bool _isUnauthorizedError(String errorMessage) {
    return errorMessage.contains('401') ||
           errorMessage.contains('403') ||
           errorMessage.contains('unauthorized') ||
           errorMessage.contains('forbidden') ||
           errorMessage.contains('access denied');
  }

  // 데이터 파싱 에러 판별
  static bool _isParsingError(String errorMessage) {
    return errorMessage.contains('formatexception') ||
           errorMessage.contains('parsing') ||
           errorMessage.contains('json') ||
           errorMessage.contains('deserialize') ||
           errorMessage.contains('invalid format');
  }

  // 찾을 수 없음 에러 판별 (HTTP 404)
  static bool _isNotFoundError(String errorMessage) {
    return errorMessage.contains('404') ||
           errorMessage.contains('not found') ||
           errorMessage.contains('찾을 수 없습니다') ||
           errorMessage.contains('does not exist');
  }
}