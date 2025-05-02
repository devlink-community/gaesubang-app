import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase({required AuthRepository repository}) : _repository = repository;

  Future<AsyncValue<Member>> execute({
    required String email,
    required String password,
  }) async {
    final result = await _repository.login(email: email, password: password);

    switch (result) {
      case Success(data: final user):
        return AsyncData(user);
      case Error(failure: final error):
        return AsyncError(error, error.stackTrace ?? StackTrace.current);
    }
  }
}
