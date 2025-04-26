import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';

@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.success(T data) = Success<T>;
  const factory Result.error(Failure failure) = Error<T>;
}

/// 실패 정보 구조
class Failure {
  final FailureType type;
  final String message;
  final Object? cause;

  const Failure(this.type, this.message, {this.cause});

  bool get isNetwork => type == FailureType.network;
  bool get isTimeout => type == FailureType.timeout;

  @override
  String toString() => 'Failure(type: $type, message: $message, cause: $cause)';
}

/// 실패 유형 분류
enum FailureType { network, unauthorized, timeout, server, parsing, unknown }

/// Exception을 Failure로 매핑하는 유틸
Failure mapExceptionToFailure(Object error) {
  final message = error.toString();
  if (message.contains('network')) {
    return const Failure(FailureType.network, '네트워크 오류가 발생했습니다');
  } else if (message.contains('timeout')) {
    return const Failure(FailureType.timeout, '요청 시간이 초과되었습니다');
  } else if (message.contains('unauthorized')) {
    return const Failure(FailureType.unauthorized, '인증 오류입니다');
  } else {
    return const Failure(FailureType.unknown, '알 수 없는 오류가 발생했습니다');
  }
}
