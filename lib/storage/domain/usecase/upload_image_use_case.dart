// lib/storage/domain/usecase/upload_image_use_case.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/storage/domain/repository/storage_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 단일 이미지 업로드 유즈케이스
class UploadImageUseCase {
  final StorageRepository _repository;

  const UploadImageUseCase({required StorageRepository repo})
    : _repository = repo;

  /// 이미지 업로드 실행
  ///
  /// [folderPath]: 저장할 경로
  /// [fileName]: 파일명
  /// [bytes]: 이미지 바이트 데이터
  /// [metadata]: 추가 메타데이터
  Future<AsyncValue<String>> execute({
    required String folderPath,
    required String fileName,
    required List<int> bytes,
    Map<String, String>? metadata,
  }) async {
    final result = await _repository.uploadImage(
      folderPath: folderPath,
      fileName: fileName,
      bytes: bytes,
      metadata: metadata,
    );

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
