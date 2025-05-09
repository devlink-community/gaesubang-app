// lib/auth/domain/usecase/signup_use_case.dart
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SignupUseCase {
  final AuthRepository _repository;

  SignupUseCase({required AuthRepository repository})
      : _repository = repository;

  Future<AsyncValue<Member>> execute({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final result = await _repository.signup(
      email: email,
      password: password,
      nickname: nickname,
    );

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}