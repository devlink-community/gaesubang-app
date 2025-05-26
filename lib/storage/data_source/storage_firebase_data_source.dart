// lib/storage/data_source/storage_firebase_data_source.dart
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'storage_data_source.dart';

class StorageFirebaseDataSource implements StorageDataSource {
  final FirebaseStorage _storage;

  StorageFirebaseDataSource({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<String> uploadImage({
    required String folderPath,
    required String fileName,
    required List<int> bytes,
    Map<String, String>? metadata,
  }) async {
    return ApiCallDecorator.wrap(
      'StorageFirebase.uploadImage',
      () async {
        final startTime = TimeFormatter.nowInSeoul();
        AppLogger.info(
          '이미지 업로드 시작: $folderPath/$fileName',
          tag: 'StorageDataSource',
        );

        try {
          // 경로 형식: {folderPath}/{fileName}
          final storagePath = '$folderPath/$fileName';

          // 메타데이터 설정
          final settableMetadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: metadata,
          );

          AppLogger.logState('업로드 정보', {
            'path': storagePath,
            'size': '${(bytes.length / 1024).toStringAsFixed(1)} KB',
            'metadata': metadata?.toString() ?? 'none',
          });

          // 바이트 데이터 직접 업로드
          final uploadTask = _storage
              .ref(storagePath)
              .putData(Uint8List.fromList(bytes), settableMetadata);

          // 업로드 진행 상황 모니터링
          final progressSubscription = uploadTask.snapshotEvents.listen((
            TaskSnapshot snapshot,
          ) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            AppLogger.debug(
              '업로드 진행률: ${(progress * 100).toStringAsFixed(1)}%',
              tag: 'StorageDataSource',
            );
          });

          // 업로드 완료 대기
          final taskSnapshot = await uploadTask;

          // 리스너 정리
          await progressSubscription.cancel();

          // 다운로드 URL 반환
          final downloadUrl = await taskSnapshot.ref.getDownloadURL();

          final duration = TimeFormatter.nowInSeoul().difference(startTime);
          AppLogger.logPerformance('이미지 업로드 완료', duration);

          AppLogger.info(
            '이미지 업로드 성공: ${downloadUrl.length > 50 ? "${downloadUrl.substring(0, 50)}..." : downloadUrl}',
            tag: 'StorageDataSource',
          );

          return downloadUrl;
        } catch (e, st) {
          final duration = TimeFormatter.nowInSeoul().difference(startTime);
          AppLogger.logPerformance('이미지 업로드 실패', duration);

          AppLogger.error(
            '이미지 업로드 실패: $folderPath/$fileName',
            tag: 'StorageDataSource',
            error: e,
            stackTrace: st,
          );

          rethrow; // 원본 예외를 그대로 전달
        }
      },
      params: {'folderPath': folderPath, 'fileName': fileName},
    );
  }

  @override
  Future<List<String>> uploadImages({
    required String folderPath,
    required String fileNamePrefix,
    required List<List<int>> bytesList,
    Map<String, String>? metadata,
  }) async {
    return ApiCallDecorator.wrap(
      'StorageFirebase.uploadImages',
      () async {
        final startTime = TimeFormatter.nowInSeoul();
        AppLogger.info(
          '다중 이미지 업로드 시작: ${bytesList.length}개',
          tag: 'StorageDataSource',
        );

        final List<String> uploadedUrls = [];

        // 병렬 처리를 위한 Future 리스트
        final futures = <Future<String>>[];

        // 각 이미지에 대한 업로드 작업 추가
        for (int i = 0; i < bytesList.length; i++) {
          final fileName = '${fileNamePrefix}_$i.jpg';
          AppLogger.debug('업로드 작업 추가: $fileName', tag: 'StorageDataSource');

          futures.add(
            uploadImage(
              folderPath: folderPath,
              fileName: fileName,
              bytes: bytesList[i],
              metadata: metadata,
            ),
          );
        }

        try {
          // 모든 업로드 완료 대기
          final results = await Future.wait(futures);
          uploadedUrls.addAll(results);

          final duration = TimeFormatter.nowInSeoul().difference(startTime);
          AppLogger.logPerformance('다중 이미지 업로드 완료', duration);

          AppLogger.info(
            '다중 이미지 업로드 성공: ${uploadedUrls.length}개',
            tag: 'StorageDataSource',
          );

          AppLogger.logState('업로드 결과', {
            '요청 개수': bytesList.length,
            '성공 개수': uploadedUrls.length,
            '소요 시간': '${duration.inMilliseconds}ms',
          });

          return uploadedUrls;
        } catch (e, st) {
          final duration = TimeFormatter.nowInSeoul().difference(startTime);
          AppLogger.logPerformance('다중 이미지 업로드 실패', duration);

          AppLogger.error(
            '다중 이미지 업로드 실패',
            tag: 'StorageDataSource',
            error: e,
            stackTrace: st,
          );

          rethrow; // 원본 예외를 그대로 전달
        }
      },
      params: {'folderPath': folderPath, 'count': bytesList.length},
    );
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    return ApiCallDecorator.wrap('StorageFirebase.deleteImage', () async {
      AppLogger.info(
        '이미지 삭제 시작: ${imageUrl.length > 50 ? "${imageUrl.substring(0, 50)}..." : imageUrl}',
        tag: 'StorageDataSource',
      );

      try {
        // URL에서 파일 경로 추출
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();

        AppLogger.info('이미지 삭제 성공', tag: 'StorageDataSource');
      } catch (e, st) {
        AppLogger.error(
          '이미지 삭제 실패',
          tag: 'StorageDataSource',
          error: e,
          stackTrace: st,
        );

        rethrow; // 원본 예외를 그대로 전달
      }
    }, params: {'imageUrl': imageUrl});
  }

  @override
  Future<void> deleteFolder(String folderPath) async {
    return ApiCallDecorator.wrap('StorageFirebase.deleteFolder', () async {
      AppLogger.info('폴더 삭제 시작: $folderPath', tag: 'StorageDataSource');

      try {
        // 폴더 내 모든 파일 목록 가져오기
        final result = await _storage.ref(folderPath).listAll();

        AppLogger.logState('폴더 내용', {
          '파일 개수': result.items.length,
          '하위 폴더 개수': result.prefixes.length,
        });

        // 각 파일 삭제
        final deleteFutures = result.items.map((item) {
          AppLogger.debug('파일 삭제: ${item.name}', tag: 'StorageDataSource');
          return item.delete();
        });
        await Future.wait(deleteFutures);

        // 하위 폴더 재귀적 삭제
        for (final prefix in result.prefixes) {
          AppLogger.debug('하위 폴더 삭제: ${prefix.name}', tag: 'StorageDataSource');
          await deleteFolder(prefix.fullPath);
        }

        AppLogger.info(
          '폴더 삭제 완료: ${result.items.length}개 파일, ${result.prefixes.length}개 하위 폴더',
          tag: 'StorageDataSource',
        );
      } catch (e, st) {
        AppLogger.error(
          '폴더 삭제 실패: $folderPath',
          tag: 'StorageDataSource',
          error: e,
          stackTrace: st,
        );

        rethrow; // 원본 예외를 그대로 전달
      }
    }, params: {'folderPath': folderPath});
  }
}
