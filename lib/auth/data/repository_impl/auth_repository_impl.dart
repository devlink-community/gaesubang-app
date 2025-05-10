import 'package:devlink_mobile_app/auth/data/data_source/auth_data_source.dart';
import 'package:devlink_mobile_app/auth/data/data_source/profile_data_source.dart';
import 'package:devlink_mobile_app/auth/data/dto/profile_dto.dart';
import 'package:devlink_mobile_app/auth/data/dto/user_dto.dart';
import 'package:devlink_mobile_app/auth/data/mapper/member_mapper.dart';
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _authDataSource;
  final ProfileDataSource _profileDataSource;

  AuthRepositoryImpl({
    required AuthDataSource authDataSource,
    required profileDataSource,
  }) : _authDataSource = authDataSource,
        _profileDataSource = profileDataSource;

  @override
  Future<Result<Member>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authDataSource.fetchLogin(
        email: email,
        password: password,
      );
      final userDto = UserDto.fromJson(response);

      // 두 번째 데이터 소스에서 ProfileDto 받아오기 (사용자 프로필 정보)
      final profileResponse = await _profileDataSource.fetchUserProfile(userDto.id!);
      final profileDto = ProfileDto.fromJson(profileResponse);

      // DTO 병합 후 Member 모델로 변환
      final member = userDto.toModelFromProfile(profileDto);

      return Result.success(member);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Future<Result<Member>> signup({
    required String email,
    required String password,
    required String nickname,
  }) async {
    try {
      final response = await _authDataSource.createUser(
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
  Future<Result<Member?>> getCurrentUser() async {
    try {
      final response = await _authDataSource.fetchCurrentUser();
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
      await _authDataSource.signOut();
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Future<Result<bool>> checkNicknameAvailability(String nickname) async {
    try {
      final isAvailable = await _authDataSource.checkNicknameAvailability(nickname);
      return Result.success(isAvailable);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Future<Result<bool>> checkEmailAvailability(String email) async {
    try {
      final isAvailable = await _authDataSource.checkEmailAvailability(email);
      return Result.success(isAvailable);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Future<Result<void>> resetPassword(String email) async {
    try {
      await _authDataSource.sendPasswordResetEmail(email);
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Future<Result<void>> deleteAccount(String email) async {
    try {
      await _authDataSource.deleteAccount(email);
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }
}