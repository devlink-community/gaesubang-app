// lib/storage/data_source/storage_firebase_data_source.dart
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
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
        try {
          // 경로 형식: {folderPath}/{fileName}
          final storagePath = '$folderPath/$fileName';

          // 메타데이터 설정
          final settableMetadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: metadata,
          );

          // 바이트 데이터 직접 업로드
          final uploadTask = _storage
              .ref(storagePath)
              .putData(Uint8List.fromList(bytes), settableMetadata);

          // 업로드 완료 대기
          final taskSnapshot = await uploadTask;

          // 다운로드 URL 반환
          return await taskSnapshot.ref.getDownloadURL();
        } catch (e, st) {
          debugPrint('이미지 업로드 실패: $e\n$st');
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
        final List<String> uploadedUrls = [];

        // 병렬 처리를 위한 Future 리스트
        final futures = <Future<String>>[];

        // 각 이미지에 대한 업로드 작업 추가
        for (int i = 0; i < bytesList.length; i++) {
          final fileName = '${fileNamePrefix}_$i.jpg';
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

          return uploadedUrls;
        } catch (e, st) {
          debugPrint('다중 이미지 업로드 실패: $e\n$st');
          rethrow; // 원본 예외를 그대로 전달
        }
      },
      params: {'folderPath': folderPath, 'count': bytesList.length},
    );
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    return ApiCallDecorator.wrap('StorageFirebase.deleteImage', () async {
      try {
        // URL에서 파일 경로 추출
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      } catch (e, st) {
        debugPrint('이미지 삭제 실패: $e\n$st');
        rethrow; // 원본 예외를 그대로 전달
      }
    }, params: {'imageUrl': imageUrl});
  }

  @override
  Future<void> deleteFolder(String folderPath) async {
    return ApiCallDecorator.wrap('StorageFirebase.deleteFolder', () async {
      try {
        // 폴더 내 모든 파일 목록 가져오기
        final result = await _storage.ref(folderPath).listAll();

        // 각 파일 삭제
        final deleteFutures = result.items.map((item) => item.delete());
        await Future.wait(deleteFutures);

        // 하위 폴더 재귀적 삭제
        for (final prefix in result.prefixes) {
          await deleteFolder(prefix.fullPath);
        }
      } catch (e, st) {
        debugPrint('폴더 삭제 실패: $e\n$st');
        rethrow; // 원본 예외를 그대로 전달
      }
    }, params: {'folderPath': folderPath});
  }
}
