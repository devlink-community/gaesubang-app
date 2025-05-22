// lib/auth/domain/usecase/get_user_profile_use_case.dart
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../auth/domain/model/member.dart';

class GetUserProfileUseCase {
  final AuthRepository _repository;

  GetUserProfileUseCase({required AuthRepository repository})
    : _repository = repository;

  Future<AsyncValue<Member>> execute(String userId) async {
    final result = await _repository.getUserProfile(userId);

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, StackTrace.current);
    }
  }
}
