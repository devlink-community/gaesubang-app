// lib/auth/domain/usecase/core/get_current_user_use_case.dart
import 'package:devlink_mobile_app/auth/domain/model/user.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_core_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetCurrentUserUseCase {
  final AuthCoreRepository _repository;

  GetCurrentUserUseCase({required AuthCoreRepository repository})
    : _repository = repository;

  Future<AsyncValue<User>> execute() async {
    final result = await _repository.getCurrentUser();

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
