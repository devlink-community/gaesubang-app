// lib/auth/domain/usecase/update_profile_image_use_case.dart
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UpdateProfileImageUseCase {
  final AuthRepository _repository;

  UpdateProfileImageUseCase({required AuthRepository repository})
    : _repository = repository;

  Future<AsyncValue<Member>> execute(String imagePath) async {
    final result = await _repository.updateProfileImage(imagePath);

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
