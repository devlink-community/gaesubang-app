// lib/auth/data/repository_impl/auth_activity_repository_impl.dart
import 'package:devlink_mobile_app/auth/data/data_source/auth_data_source.dart';
import 'package:devlink_mobile_app/auth/data/mapper/summary_mapper.dart';
import 'package:devlink_mobile_app/auth/domain/model/activity.dart';
import 'package:devlink_mobile_app/auth/domain/model/summary.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_activity_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/exception_mappers/auth_exception_mapper.dart';

class AuthActivityRepositoryImpl implements AuthActivityRepository {
  final AuthDataSource _authDataSource;

  AuthActivityRepositoryImpl({
    required AuthDataSource authDataSource,
  }) : _authDataSource = authDataSource;

  @override
  Future<Result<Summary?>> getUserSummary(String userId) async {
    try {
      final summaryDto = await _authDataSource.fetchUserSummary(userId);
      final summary = summaryDto?.toModel();
      return Result.success(summary);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<void>> updateUserSummary({
    required String userId,
    required Summary summary,
  }) async {
    try {
      final summaryDto = summary.toDto();
      await _authDataSource.updateUserSummary(
        userId: userId,
        summary: summaryDto,
      );
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<Activity?>> getUserActivity(String userId) async {
    try {
      // TODO: AuthDataSource에 getUserActivity 메서드 추가 필요
      // 현재는 임시로 null 반환
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<void>> updateUserActivity({
    required String userId,
    required Activity activity,
  }) async {
    try {
      // TODO: AuthDataSource에 updateUserActivity 메서드 추가 필요
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }
}
