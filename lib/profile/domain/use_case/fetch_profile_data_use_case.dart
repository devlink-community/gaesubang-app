import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/auth_error_messages.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FetchProfileUserUseCase {
  final AuthRepository _authRepository;

  FetchProfileUserUseCase(this._authRepository);

  Future<AsyncValue<Member>> execute() async {
    final result = await _authRepository.getCurrentUser();
    switch (result) {
      case Success(data: final user):
        if (user == null) {
          return AsyncError(
            Exception(AuthErrorMessages.noLoggedInUser),
            StackTrace.current,
          );
        }
        return AsyncData(user);
      case Error(failure: final failure):
        return AsyncError(failure, StackTrace.current);
    }
  }
}
