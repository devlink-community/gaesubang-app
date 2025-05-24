// lib/auth/data/repository_impl/auth_profile_repository_impl.dart
import 'package:devlink_mobile_app/auth/data/data_source/auth_data_source.dart';
import 'package:devlink_mobile_app/auth/data/mapper/user_mapper.dart';
import 'package:devlink_mobile_app/auth/domain/model/user.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_profile_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/exception_mappers/auth_exception_mapper.dart';

class AuthProfileRepositoryImpl implements AuthProfileRepository {
  final AuthDataSource _authDataSource;

  AuthProfileRepositoryImpl({
    required AuthDataSource authDataSource,
  }) : _authDataSource = authDataSource;

  @override
  Future<Result<User>> updateProfile({
    required String nickname,
    String? description,
    String? position,
    String? skills,
  }) async {
    try {
      final response = await _authDataSource.updateUser(
        nickname: nickname,
        description: description,
        position: position,
        skills: skills,
      );
      final user = response.toUser();
      return Result.success(user);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<User>> updateProfileImage(String imagePath) async {
    try {
      final response = await _authDataSource.updateUserImage(imagePath);
      final user = response.toUser();
      return Result.success(user);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<User>> getUserProfile(String userId) async {
    try {
      final userDto = await _authDataSource.fetchUserProfile(userId);
      final user = userDto.toModel();
      return Result.success(user);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }
}
