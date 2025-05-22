import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// 이미지 압축을 위한 유틸리티 클래스
class ImageCompressionUtils {
  /// compute에서 실행될 이미지 압축 함수
  static Future<Uint8List> _compressImageInIsolate(
    Map<String, dynamic> params,
  ) {
    return _performCompression(params);
  }

  /// 실제 압축 작업 수행
  static Future<Uint8List> _performCompression(
    Map<String, dynamic> params,
  ) async {
    final String imagePath = params['path'];
    final int maxWidth = params['maxWidth'];
    final int maxHeight = params['maxHeight'];
    final int quality = params['quality'];

    // 원본 이미지 읽기
    final File imageFile = File(imagePath);
    final Uint8List originalImageBytes = await imageFile.readAsBytes();

    // 이미지 디코딩
    final img.Image? originalImage = img.decodeImage(originalImageBytes);
    if (originalImage == null) {
      throw Exception('이미지 디코딩에 실패했습니다');
    }

    // 이미지 리사이즈 (종횡비 유지) - 올바른 파라미터 사용
    final img.Image resizedImage = img.copyResize(
      originalImage,
      width: maxWidth,
      height: maxHeight,
      maintainAspect: true, // 올바른 파라미터명
    );

    // JPEG로 인코딩 (압축)
    final Uint8List compressedImageBytes = Uint8List.fromList(
      img.encodeJpg(resizedImage, quality: quality),
    );

    return compressedImageBytes;
  }

  /// 메인 스레드에서 호출하는 이미지 압축 메서드
  static Future<Uint8List> compressImage({
    required String imagePath,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 80,
  }) async {
    // 웹 환경에서는 compute를 사용하지 않고 직접 처리
    if (kIsWeb) {
      return await _performCompression({
        'path': imagePath,
        'maxWidth': maxWidth,
        'maxHeight': maxHeight,
        'quality': quality,
      });
    }

    // 모바일 환경에서는 compute 사용
    return await compute(_compressImageInIsolate, {
      'path': imagePath,
      'maxWidth': maxWidth,
      'maxHeight': maxHeight,
      'quality': quality,
    });
  }

  /// compute를 사용한 간단한 압축 (권장 방법)
  static Future<Uint8List> compressImageWithCompute({
    required String imagePath,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 80,
  }) async {
    final params = {
      'path': imagePath,
      'maxWidth': maxWidth,
      'maxHeight': maxHeight,
      'quality': quality,
    };

    return compute(_compressImageInIsolate, params);
  }

  /// 이미지 파일 크기 확인
  static Future<int> getImageFileSize(String imagePath) async {
    final File imageFile = File(imagePath);
    final int fileSizeBytes = await imageFile.length();
    return fileSizeBytes;
  }

  /// 압축이 필요한지 확인
  static Future<bool> shouldCompressImage({
    required String imagePath,
    int maxFileSizeKB = 500, // 500KB 이상이면 압축
  }) async {
    final int fileSizeBytes = await getImageFileSize(imagePath);
    final int fileSizeKB = fileSizeBytes ~/ 1024;
    return fileSizeKB > maxFileSizeKB;
  }

  /// 압축된 이미지를 임시 파일로 저장
  static Future<File> saveCompressedImageToTemp({
    required Uint8List compressedBytes,
    String? customFileName,
  }) async {
    final String fileName =
        customFileName ??
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final Directory tempDir = Directory.systemTemp;
    final File tempFile = File('${tempDir.path}/$fileName');

    await tempFile.writeAsBytes(compressedBytes);
    return tempFile;
  }

  /// 전체 압축 프로세스 (압축 + 임시 파일 저장)
  static Future<File> compressAndSaveImage({
    required String originalImagePath,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 80,
    int maxFileSizeKB = 500,
    String? customFileName,
  }) async {
    // 압축이 필요한지 확인
    final bool shouldCompress = await shouldCompressImage(
      imagePath: originalImagePath,
      maxFileSizeKB: maxFileSizeKB,
    );

    if (!shouldCompress) {
      // 압축이 필요 없으면 원본 파일 반환
      return File(originalImagePath);
    }

    // 이미지 압축
    final Uint8List compressedBytes = await compressImage(
      imagePath: originalImagePath,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      quality: quality,
    );

    // 압축된 이미지를 임시 파일로 저장
    final File compressedFile = await saveCompressedImageToTemp(
      compressedBytes: compressedBytes,
      customFileName: customFileName,
    );

    debugPrint('✅ 이미지 압축 완료: ${originalImagePath} → ${compressedFile.path}');
    debugPrint(
      '   원본 크기: ${await getImageFileSize(originalImagePath) ~/ 1024}KB',
    );
    debugPrint('   압축 크기: ${await compressedFile.length() ~/ 1024}KB');

    return compressedFile;
  }
}
