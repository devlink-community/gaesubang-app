// lib/auth/domain/usecase/signout_use_case.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/result/result.dart';
import '../repository/auth_repository.dart';

class SignoutUseCase {
  final AuthRepository _repository;

  SignoutUseCase({required AuthRepository repository})
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
