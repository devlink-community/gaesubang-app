// lib/storage/data/repository_impl/storage_repository_impl.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/exception_mappers/storage_exception_mapper.dart';
import 'package:devlink_mobile_app/storage/data_source/storage_data_source.dart';
import 'package:devlink_mobile_app/storage/domain/repository/storage_repository.dart';

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

          AppLogger.info(
            '이미지 업로드 성공: $folderPath/$fileName',
            tag: 'StorageRepository',
          );

          return Result.success(downloadUrl);
        } catch (e, st) {
          AppLogger.error(
            '이미지 업로드 실패: $folderPath/$fileName',
            tag: 'StorageRepository',
            error: e,
            stackTrace: st,
          );

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

          AppLogger.info(
            '여러 이미지 업로드 성공: $folderPath/${fileNamePrefix}_* (${bytesList.length}개)',
            tag: 'StorageRepository',
          );

          return Result.success(downloadUrls);
        } catch (e, st) {
          AppLogger.error(
            '여러 이미지 업로드 실패: $folderPath/${fileNamePrefix}_* (${bytesList.length}개)',
            tag: 'StorageRepository',
            error: e,
            stackTrace: st,
          );

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

        AppLogger.info(
          '이미지 삭제 성공: $imageUrl',
          tag: 'StorageRepository',
        );

        return const Result.success(null);
      } catch (e, st) {
        AppLogger.error(
          '이미지 삭제 실패: $imageUrl',
          tag: 'StorageRepository',
          error: e,
          stackTrace: st,
        );

        return Result.error(StorageExceptionMapper.mapStorageException(e, st));
      }
    }, params: {'imageUrl': imageUrl});
  }

  @override
  Future<Result<void>> deleteFolder(String folderPath) async {
    return ApiCallDecorator.wrap('StorageRepository.deleteFolder', () async {
      try {
        await _dataSource.deleteFolder(folderPath);

        AppLogger.info(
          '폴더 삭제 성공: $folderPath',
          tag: 'StorageRepository',
        );

        return const Result.success(null);
      } catch (e, st) {
        AppLogger.error(
          '폴더 삭제 실패: $folderPath',
          tag: 'StorageRepository',
          error: e,
          stackTrace: st,
        );

        return Result.error(StorageExceptionMapper.mapStorageException(e, st));
      }
    }, params: {'folderPath': folderPath});
  }
}
