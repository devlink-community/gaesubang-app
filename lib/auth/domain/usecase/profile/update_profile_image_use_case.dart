// lib/auth/domain/usecase/profile/update_profile_image_use_case.dart
import 'dart:io';

import 'package:devlink_mobile_app/auth/domain/model/user.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_profile_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/image_compression.dart';
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 프로필 이미지 업데이트 UseCase
class UpdateProfileImageUseCase {
  final AuthProfileRepository _repository;

  UpdateProfileImageUseCase(AuthProfileRepository repository)
    : _repository = repository;

  /// 프로필 이미지를 업데이트합니다
  ///
  /// [imagePath]: 선택된 이미지의 로컬 파일 경로
  ///
  /// 처리 과정:
  /// 1. 이미지 파일 유효성 검사
  /// 2. 이미지 압축 (필요한 경우)
  /// 3. 서버에 업로드
  /// 4. 업데이트된 사용자 정보 반환
  Future<AsyncValue<User>> execute(String imagePath) async {
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
                'profile_${TimeFormatter.nowInSeoul().millisecondsSinceEpoch}.jpg',
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
      final result = await _repository.updateProfileImage(
        imageFileToUpload.path,
      );

      // 6. Result<User> 타입 처리 (freezed sealed class 패턴 매칭)
      switch (result) {
        case Success<User>(:final data):
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

        case Error<User>(:final failure):
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
}
