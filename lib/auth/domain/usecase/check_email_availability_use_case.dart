// lib/auth/domain/usecase/check_email_availability_use_case.dart
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CheckEmailAvailabilityUseCase {
  final AuthRepository _repository;

  CheckEmailAvailabilityUseCase({required AuthRepository repository})
      : _repository = repository;

  Future<AsyncValue<bool>> execute(String email) async {
    final result = await _repository.checkEmailAvailability(email);

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}