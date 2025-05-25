// lib/auth/domain/repository/auth_activity_repository.dart 수정
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

  /// 타이머 활동에 따른 Summary 업데이트
  /// 타이머 종료 시 호출되어 사용자의 통계 정보를 갱신
  Future<Result<void>> updateSummaryForTimerActivity({
    required String userId,
    required String groupId,
    required int elapsedSeconds,
    required String dateKey,
  });
}
