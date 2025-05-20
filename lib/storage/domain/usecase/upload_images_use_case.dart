// lib/storage/domain/usecase/upload_images_use_case.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/storage/domain/repository/storage_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 다중 이미지 업로드 유즈케이스
class UploadImagesUseCase {
  final StorageRepository _repository;

  const UploadImagesUseCase({required StorageRepository repo})
    : _repository = repo;

  /// 다중 이미지 업로드 실행
  ///
  /// [folderPath]: 저장할 경로
  /// [fileNamePrefix]: 파일명 접두사
  /// [bytesList]: 이미지 바이트 데이터 리스트
  /// [metadata]: 추가 메타데이터
  Future<AsyncValue<List<Uri>>> execute({
    required String folderPath,
    required String fileNamePrefix,
    required List<List<int>> bytesList,
    Map<String, String>? metadata,
  }) async {
    final result = await _repository.uploadImages(
      folderPath: folderPath,
      fileNamePrefix: fileNamePrefix,
      bytesList: bytesList,
      metadata: metadata,
    );

    switch (result) {
      case Success(:final data):
        // String URL 리스트를 Uri 객체 리스트로 변환
        final uriList = data.map((url) => Uri.parse(url)).toList();
        return AsyncData(uriList);

      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
