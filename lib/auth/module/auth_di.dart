import 'package:devlink_mobile_app/auth/data/data_source/auth_data_source.dart';
import 'package:devlink_mobile_app/auth/data/data_source/mock_auth_data_source.dart';
import 'package:devlink_mobile_app/auth/data/repository_impl/auth_repository_impl.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/login_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/mock_login_user_case.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_di.g.dart';

/// AuthDataSource Provider
@riverpod
AuthDataSource authDataSource(Ref ref) {
  return MockAuthDataSource(); // (지금은 Mock, 나중에 Firebase로 교체 가능)
}

/// AuthRepository Provider
@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(ref.watch(authDataSourceProvider));
}

/// LoginUseCase Provider
@riverpod
LoginUseCase loginUseCase(Ref ref) {
  return LoginUseCase(repository: ref.watch(authRepositoryProvider));
}

@riverpod
LoginUseCase mockLoginUseCase(Ref ref) {
  return MockLoginUseCase();
}
