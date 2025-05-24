// lib/profile/domain/usecase/get_user_profile_use_case.dart
import 'package:devlink_mobile_app/auth/domain/model/user.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_profile_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetUserProfileUseCase {
  final AuthProfileRepository _repository;

  GetUserProfileUseCase({required AuthProfileRepository repository})
    : _repository = repository;

  Future<AsyncValue<User>> execute(String userId) async {
    final result = await _repository.getUserProfile(userId);

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
