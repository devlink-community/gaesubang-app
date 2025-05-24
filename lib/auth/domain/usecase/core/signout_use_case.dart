// lib/auth/domain/usecase/core/signout_use_case.dart
import 'package:devlink_mobile_app/auth/domain/repository/auth_core_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SignoutUseCase {
  final AuthCoreRepository _repository;

  SignoutUseCase({required AuthCoreRepository repository})
    : _repository = repository;

  Future<AsyncValue<void>> execute() async {
    final result = await _repository.signOut();

    switch (result) {
      case Success():
        return const AsyncData(null);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
