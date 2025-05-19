// lib/auth/domain/usecase/update_profile_image_use_case.dart
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class UpdateProfileImageUseCase {
  final AuthRepository _repository;

  UpdateProfileImageUseCase({required AuthRepository repository})
    : _repository = repository;

  Future<AsyncValue<Member>> execute(XFile imageFile) async {
    // TODO: AuthRepository에 updateProfileImage 메서드 추가 필요
    // 현재는 getCurrentUser로 대체하여 임시 처리
    final result = await _repository.getCurrentUser();

    switch (result) {
      case Success(:final data):
        if (data == null) {
          return AsyncError(Exception('로그인된 사용자가 없습니다'), StackTrace.current);
        }

        // 임시로 로컬 파일 경로로 이미지 업데이트
        final updatedMember = data.copyWith(image: imageFile.path);

        return AsyncData(updatedMember);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
