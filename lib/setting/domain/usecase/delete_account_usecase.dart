import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../auth/domain/repository/auth_repository.dart';
import '../../../core/result/result.dart';

class DeleteAccountUseCase {
  final AuthRepository _repository;

  DeleteAccountUseCase(this._repository);

  Future<AsyncValue<void>> execute() async {
    final result = await _repository.deleteAccount();

    switch (result) {
      case Success():
        return const AsyncData(null);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
