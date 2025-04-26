import 'package:devlink_mobile_app/auth/domain/model/user.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';

class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase({required AuthRepository repository}) : _repository = repository;

  Future<User> execute({
    required String email,
    required String password,
  }) async {
    final result = await _repository.login(email: email, password: password);

    switch (result) {
      case Success(data: final user):
        return user;
      case Error(failure: final error):
        throw error;
    }
  }
}
