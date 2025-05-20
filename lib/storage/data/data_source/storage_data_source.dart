// lib/storage/data/data_source/storage_data_source.dart
abstract interface class StorageDataSource {
  /// 이미지를 스토리지에 업로드하고 다운로드 URL 반환
  ///
  /// [folderPath]: 스토리지 내 폴더 경로 (예: 'posts/user1/post123')
  /// [fileName]: 파일명 (예: 'image1.jpg')
  /// [bytes]: 이미지 바이트 데이터
  /// [metadata]: 추가 메타데이터
  Future<String> uploadImage({
    required String folderPath,
    required String fileName,
    required List<int> bytes,
    Map<String, String>? metadata,
  });

  /// 여러 이미지를 스토리지에 업로드하고 다운로드 URL 리스트 반환
  ///
  /// [folderPath]: 스토리지 내 폴더 경로 (예: 'posts/user1/post123')
  /// [fileNamePrefix]: 파일명 접두사 (예: 'image')
  /// [bytesList]: 이미지 바이트 데이터 리스트
  /// [metadata]: 추가 메타데이터
  Future<List<String>> uploadImages({
    required String folderPath,
    required String fileNamePrefix,
    required List<List<int>> bytesList,
    Map<String, String>? metadata,
  });

  /// 스토리지에서 이미지 삭제
  ///
  /// [imageUrl]: 삭제할 이미지의 URL
  Future<void> deleteImage(String imageUrl);

  /// 스토리지 폴더 내 모든 이미지 삭제
  ///
  /// [folderPath]: 삭제할 폴더 경로 (예: 'posts/user1/post123')
  Future<void> deleteFolder(String folderPath);
}
