// lib/storage/data/repository_impl/storage_repository_impl.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/exception_mappers/storage_exception_mapper.dart';
import 'package:devlink_mobile_app/storage/data_source/storage_data_source.dart';
import 'package:devlink_mobile_app/storage/domain/repository/storage_repository.dart';
import 'package:flutter/foundation.dart';

class StorageRepositoryImpl implements StorageRepository {
  final StorageDataSource _dataSource;

  StorageRepositoryImpl({required StorageDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Result<String>> uploadImage({
    required String folderPath,
    required String fileName,
    required List<int> bytes,
    Map<String, String>? metadata,
  }) async {
    return ApiCallDecorator.wrap(
      'StorageRepository.uploadImage',
      () async {
        try {
          final downloadUrl = await _dataSource.uploadImage(
            folderPath: folderPath,
            fileName: fileName,
            bytes: bytes,
            metadata: metadata,
          );
          return Result.success(downloadUrl);
        } catch (e, st) {
          debugPrint('이미지 업로드 실패: $e');
          return Result.error(
            StorageExceptionMapper.mapStorageException(e, st),
          );
        }
      },
      params: {'folderPath': folderPath, 'fileName': fileName},
    );
  }

  @override
  Future<Result<List<String>>> uploadImages({
    required String folderPath,
    required String fileNamePrefix,
    required List<List<int>> bytesList,
    Map<String, String>? metadata,
  }) async {
    return ApiCallDecorator.wrap(
      'StorageRepository.uploadImages',
      () async {
        try {
          final downloadUrls = await _dataSource.uploadImages(
            folderPath: folderPath,
            fileNamePrefix: fileNamePrefix,
            bytesList: bytesList,
            metadata: metadata,
          );
          return Result.success(downloadUrls);
        } catch (e, st) {
          debugPrint('여러 이미지 업로드 실패: $e');
          return Result.error(
            StorageExceptionMapper.mapStorageException(e, st),
          );
        }
      },
      params: {'folderPath': folderPath, 'count': bytesList.length},
    );
  }

  @override
  Future<Result<void>> deleteImage(String imageUrl) async {
    return ApiCallDecorator.wrap('StorageRepository.deleteImage', () async {
      try {
        await _dataSource.deleteImage(imageUrl);
        return const Result.success(null);
      } catch (e, st) {
        debugPrint('이미지 삭제 실패: $e');
        return Result.error(StorageExceptionMapper.mapStorageException(e, st));
      }
    }, params: {'imageUrl': imageUrl});
  }

  @override
  Future<Result<void>> deleteFolder(String folderPath) async {
    return ApiCallDecorator.wrap('StorageRepository.deleteFolder', () async {
      try {
        await _dataSource.deleteFolder(folderPath);
        return const Result.success(null);
      } catch (e, st) {
        debugPrint('폴더 삭제 실패: $e');
        return Result.error(StorageExceptionMapper.mapStorageException(e, st));
      }
    }, params: {'folderPath': folderPath});
  }
}
