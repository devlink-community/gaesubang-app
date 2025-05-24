import 'dart:io';

import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/result/result.dart';
import '../../../core/utils/image_compression.dart';

/// 프로필 이미지 업데이트 UseCase
class UpdateProfileImageUseCase {
  final AuthRepository _authRepository;

  UpdateProfileImageUseCase(this._authRepository);

  /// 프로필 이미지를 업데이트합니다
  ///
  /// [imagePath]: 선택된 이미지의 로컬 파일 경로
  ///
  /// 처리 과정:
  /// 1. 이미지 파일 유효성 검사
  /// 2. 이미지 압축 (필요한 경우)
  /// 3. 서버에 업로드
  /// 4. 업데이트된 사용자 정보 반환
  Future<AsyncValue<Member>> execute(String imagePath) async {
    try {
      AppLogger.info(
        '이미지 업데이트 시작 - $imagePath',
        tag: 'ProfileImage',
      );

      // 1. 이미지 파일 유효성 검사
      final File originalImageFile = File(imagePath);
      if (!await originalImageFile.exists()) {
        AppLogger.error(
          '이미지 파일이 존재하지 않음',
          tag: 'ProfileImage',
        );
        return AsyncValue.error(
          '선택한 이미지 파일을 찾을 수 없습니다',
          StackTrace.current,
        );
      }

      // 2. 파일 크기 확인 및 로깅
      final int originalSizeKB = await originalImageFile.length() ~/ 1024;
      AppLogger.info(
        '원본 이미지 크기 - ${originalSizeKB}KB',
        tag: 'ProfileImage',
      );

      // 3. 이미지 압축 처리
      File imageFileToUpload;

      // 압축이 필요한지 확인 (500KB 이상이면 압축)
      final bool shouldCompress =
          await ImageCompressionUtils.shouldCompressImage(
            imagePath: imagePath,
            maxFileSizeKB: 500,
          );

      if (shouldCompress) {
        AppLogger.info(
          '이미지 압축 시작 (${originalSizeKB}KB > 500KB)',
          tag: 'ProfileImage',
        );

        try {
          // 이미지 압축 및 임시 파일 생성
          imageFileToUpload = await ImageCompressionUtils.compressAndSaveImage(
            originalImagePath: imagePath,
            maxWidth: 1024,
            maxHeight: 1024,
            quality: 80,
            maxFileSizeKB: 500,
            customFileName:
                'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

          final int compressedSizeKB = await imageFileToUpload.length() ~/ 1024;
          AppLogger.info(
            '이미지 압축 완료 - 압축 전: ${originalSizeKB}KB → 압축 후: ${compressedSizeKB}KB',
            tag: 'ProfileImage',
          );
          AppLogger.info(
            '압축률: ${((originalSizeKB - compressedSizeKB) / originalSizeKB * 100).toStringAsFixed(1)}%',
            tag: 'ProfileImage',
          );
        } catch (compressionError) {
          AppLogger.warning(
            '이미지 압축 실패, 원본 사용',
            tag: 'ProfileImage',
            error: compressionError,
          );
          // 압축 실패 시 원본 이미지 사용
          imageFileToUpload = originalImageFile;
        }
      } else {
        AppLogger.info(
          '이미지 압축 불필요 (${originalSizeKB}KB ≤ 500KB)',
          tag: 'ProfileImage',
        );
        imageFileToUpload = originalImageFile;
      }

      // 4. 최종 업로드 파일 크기 확인
      final int finalSizeKB = await imageFileToUpload.length() ~/ 1024;
      AppLogger.info(
        '업로드할 이미지 - ${imageFileToUpload.path} (${finalSizeKB}KB)',
        tag: 'ProfileImage',
      );

      // 5. 서버에 이미지 업로드
      AppLogger.info('서버 업로드 시작', tag: 'ProfileImage');
      final result = await _authRepository.updateProfileImage(
        imageFileToUpload.path,
      );

      // 6. Result<Member> 타입 처리 (freezed sealed class 패턴 매칭)
      switch (result) {
        case Success<Member>(:final data):
          // 7. 임시 압축 파일 정리 (원본과 다른 경우)
          if (imageFileToUpload.path != originalImageFile.path) {
            imageFileToUpload.delete().catchError((deleteError) {
              AppLogger.warning(
                '임시 파일 삭제 실패',
                tag: 'ProfileImage',
                error: deleteError,
              );
              // 파일 삭제 실패는 치명적이지 않으므로 계속 진행
            });
          }

          AppLogger.info(
            '프로필 이미지 업데이트 성공 - 새 이미지 URL: ${data.image}',
            tag: 'ProfileImage',
          );

          return AsyncValue.data(data);

        case Error<Member>(:final failure):
          AppLogger.error(
            'Repository 실패',
            tag: 'ProfileImage',
            error: failure.message,
          );

          return AsyncValue.error(failure.message, StackTrace.current);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '프로필 이미지 업데이트 실패',
        tag: 'ProfileImage',
        error: e,
        stackTrace: stackTrace,
      );

      // 사용자 친화적인 에러 메시지 제공
      String userFriendlyMessage;
      if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        userFriendlyMessage = '네트워크 연결을 확인해주세요';
      } else if (e.toString().contains('file') ||
          e.toString().contains('permission')) {
        userFriendlyMessage = '이미지 파일에 접근할 수 없습니다';
      } else if (e.toString().contains('size') ||
          e.toString().contains('large')) {
        userFriendlyMessage = '이미지 파일이 너무 큽니다';
      } else if (e.toString().contains('format') ||
          e.toString().contains('invalid')) {
        userFriendlyMessage = '지원하지 않는 이미지 형식입니다';
      } else {
        userFriendlyMessage = '이미지 업로드에 실패했습니다';
      }

      return AsyncValue.error(userFriendlyMessage, stackTrace);
    }
  }

  /// 지원되는 이미지 형식인지 확인
  bool _isSupportedImageFormat(String imagePath) {
    final String extension = imagePath.toLowerCase().split('.').last;
    const List<String> supportedFormats = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
    ];
    return supportedFormats.contains(extension);
  }

  /// 이미지 파일 크기 제한 확인 (10MB)
  Future<bool> _isWithinSizeLimit(File imageFile) async {
    const int maxSizeBytes = 10 * 1024 * 1024; // 10MB
    final int fileSizeBytes = await imageFile.length();
    return fileSizeBytes <= maxSizeBytes;
  }

  /// 추가 검증을 포함한 고급 이미지 업데이트
  Future<AsyncValue<Member>> executeWithValidation(String imagePath) async {
    try {
      AppLogger.info(
        '고급 검증과 함께 이미지 업데이트 시작',
        tag: 'ProfileImage',
      );

      final File imageFile = File(imagePath);

      // 1. 파일 존재 확인
      if (!await imageFile.exists()) {
        return AsyncValue.error('이미지 파일을 찾을 수 없습니다', StackTrace.current);
      }

      // 2. 이미지 형식 검증
      if (!_isSupportedImageFormat(imagePath)) {
        return AsyncValue.error(
          '지원하지 않는 이미지 형식입니다.\n지원 형식: JPG, PNG, GIF, BMP, WebP',
          StackTrace.current,
        );
      }

      // 3. 파일 크기 제한 확인
      if (!await _isWithinSizeLimit(imageFile)) {
        return AsyncValue.error('이미지 파일이 너무 큽니다 (최대 10MB)', StackTrace.current);
      }

      // 4. 일반 업데이트 프로세스 실행
      return await execute(imagePath);
    } catch (e, stackTrace) {
      AppLogger.error(
        '고급 검증 실패',
        tag: 'ProfileImage',
        error: e,
        stackTrace: stackTrace,
      );
      return AsyncValue.error('이미지 업데이트 검증에 실패했습니다', stackTrace);
    }
  }
}
