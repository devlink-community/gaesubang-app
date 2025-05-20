// lib/core/utils/exception_mappers/storage_exception_mapper.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/messages/storage_error_messages.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// 스토리지 관련 예외를 Failure 객체로 변환하는 매퍼
class StorageExceptionMapper {
  const StorageExceptionMapper._(); // 인스턴스화 방지

  /// Storage 관련 예외를 Failure로 매핑
  static Failure mapStorageException(Object error, StackTrace stackTrace) {
    if (error is FirebaseException) {
      // Firebase Storage 예외 처리
      return _mapFirebaseStorageException(error, stackTrace);
    } else {
      // 기타 예외
      return Failure(
        FailureType.unknown,
        StorageErrorMessages.unknownError,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Firebase Storage 예외를 Failure로 매핑
  static Failure _mapFirebaseStorageException(
    FirebaseException error,
    StackTrace stackTrace,
  ) {
    final code = error.code;

    switch (code) {
      case 'object-not-found':
        return Failure(
          FailureType.server,
          StorageErrorMessages.fileNotFound,
          cause: error,
          stackTrace: stackTrace,
        );

      case 'unauthorized':
        return Failure(
          FailureType.unauthorized,
          StorageErrorMessages.unauthorized,
          cause: error,
          stackTrace: stackTrace,
        );

      case 'canceled':
        return Failure(
          FailureType.server,
          StorageErrorMessages.uploadCanceled,
          cause: error,
          stackTrace: stackTrace,
        );

      case 'storage/quota-exceeded':
        return Failure(
          FailureType.server,
          StorageErrorMessages.quotaExceeded,
          cause: error,
          stackTrace: stackTrace,
        );

      case 'invalid-argument':
      case 'invalid-checksum':
        return Failure(
          FailureType.validation,
          StorageErrorMessages.invalidData,
          cause: error,
          stackTrace: stackTrace,
        );

      default:
        return Failure(
          FailureType.server,
          StorageErrorMessages.uploadFailed,
          cause: error,
          stackTrace: stackTrace,
        );
    }
  }
}
