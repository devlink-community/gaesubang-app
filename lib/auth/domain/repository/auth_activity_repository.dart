// lib/auth/domain/repository/auth_activity_repository.dart
import 'package:devlink_mobile_app/auth/domain/model/summary.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/timer_activity_type.dart'; // 추가: TimerActivityType import

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
  /// 타이머 동작 시 호출되어 사용자의 통계 정보를 갱신
  ///
  /// [userId] 사용자 ID
  /// [groupId] 그룹 ID
  /// [timerState] 타이머 상태 (start, pause, resume, end 등)
  /// [elapsedSeconds] 경과 시간(초) - pause/end 상태에서만 필요
  /// [dateKey] 날짜 키 (YYYY-MM-DD 형식)
  Future<Result<void>> updateSummaryForTimerActivity({
    required String userId,
    required String groupId,
    required TimerActivityType timerState, // 추가: 타이머 상태
    int? elapsedSeconds, // nullable로 변경
    required String dateKey,
  });
}
