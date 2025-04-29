import 'package:devlink_mobile_app/auth/data/data_source/auth_data_source.dart';
import 'package:devlink_mobile_app/auth/data/dto/user_dto.dart';
import 'package:devlink_mobile_app/auth/data/mapper/user_mapper.dart';
import 'package:devlink_mobile_app/auth/domain/model/user.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dataSource.fetchLogin(
        email: email,
        password: password,
      );
      final user = UserDto.fromJson(response).toModel();
      // response를 UserDto로 변환 후 Model로 변환
      return Result.success(user);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Future<Result<User>> signup({
    required String email,
    required String password,
    required String nickname,
  }) async {
    try {
      final response = await _dataSource.createUser(
        email: email,
        password: password,
        nickname: nickname,
      );
      final user = response.toUserDto().toModel();
      return Result.success(user);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    try {
      final response = await _dataSource.fetchCurrentUser();
      if (response == null) {
        return const Result.success(null);
      }
      final user = response.toUserDto().toModel();
      return Result.success(user);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }
}
