// lib/auth/domain/repository/auth_activity_repository.dart
import 'package:devlink_mobile_app/auth/domain/model/activity.dart';
import 'package:devlink_mobile_app/auth/domain/model/summary.dart';
import 'package:devlink_mobile_app/core/result/result.dart';

/// 사용자 활동 관리 Repository
/// Summary(전체 통계)와 Activity(실시간 타이머) 관리
abstract interface class AuthActivityRepository {
  /// 사용자 Summary 조회
  Future<Result<Summary?>> getUserSummary(String userId);

  /// 사용자 Summary 업데이트
  Future<Result<void>> updateUserSummary({
    required String userId,
    required Summary summary,
  });

  /// 사용자 Activity 조회
  Future<Result<Activity?>> getUserActivity(String userId);

  /// 사용자 Activity 업데이트
  Future<Result<void>> updateUserActivity({
    required String userId,
    required Activity activity,
  });
}
