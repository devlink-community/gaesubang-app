// lib/auth/domain/usecase/update_user_stats_after_timer_use_case.dart
import 'package:devlink_mobile_app/auth/domain/model/user_focus_stats.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/calculate_user_focus_stats_use_case.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:flutter/foundation.dart';

class UpdateUserStatsAfterTimerUseCase {
  final AuthRepository _authRepository;
  final CalculateUserFocusStatsUseCase _calculateStatsUseCase;

  UpdateUserStatsAfterTimerUseCase({
    required AuthRepository authRepository,
    required CalculateUserFocusStatsUseCase calculateStatsUseCase,
  }) : _authRepository = authRepository,
       _calculateStatsUseCase = calculateStatsUseCase;

  /// 타이머 종료 후 사용자 통계를 재계산해서 업데이트
  Future<Result<void>> execute(String userId) async {
    try {
      debugPrint('🔄 UpdateUserStatsAfterTimerUseCase: 타이머 종료 후 통계 업데이트 시작');
      debugPrint('🔍 userId: $userId');

      // 1. 그룹 출석 데이터 기반으로 최신 통계 계산
      final statsResult = await _calculateStatsUseCase.execute(userId);

      if (statsResult case Error(:final failure)) {
        debugPrint('❌ 통계 계산 실패: $failure');
        return Error(failure);
      }

      final stats = (statsResult as Success).data;

      debugPrint('📊 계산된 통계:');
      debugPrint('  - 총 집중시간: ${stats.formattedTotalTime}');
      debugPrint('  - 이번 주: ${stats.formattedWeeklyTime}');
      debugPrint('  - 연속 학습일: ${stats.streakDays}일');
      debugPrint('  - 일별 데이터: ${stats.dailyFocusMinutes.length}개 항목');

      // 2. 현재 저장된 사용자 통계 조회 (먼저 Firebase에서 조회)
      final userResult = await _authRepository.getUserProfile(userId);
      if (userResult case Error(:final failure)) {
        debugPrint('⚠️ 사용자 정보 조회 실패: $failure');
        // 이전 통계를 조회할 수 없어도 새 통계를 저장은 시도
      } else {
        // 현재 사용자의 최신 데이터 확보
        final user = (userResult as Success).data;

        // 기존 통계와 비교해서 타이머 활동을 추가하는 방식으로 업데이트
        final currentStats = UserFocusStats(
          totalFocusMinutes: user.totalFocusMinutes,
          weeklyFocusMinutes: user.weeklyFocusMinutes,
          streakDays: user.streakDays,
          lastUpdated: user.lastStatsUpdated,
          dailyFocusMinutes: {}, // 기존 dailyFocusMinutes 정보는 없음 (새 통계로 대체)
        );

        debugPrint('📊 기존 통계:');
        debugPrint('  - 총 집중시간: ${currentStats.totalFocusMinutes}분');
        debugPrint('  - 이번 주: ${currentStats.weeklyFocusMinutes}분');
        debugPrint('  - 연속 학습일: ${currentStats.streakDays}일');
      }

      // 3. 오늘 날짜에 대한 타이머 활동을 파악
      final today = DateTime.now();
      final todayKey = UserFocusStats.formatDateKey(today);
      final todayMinutes = stats.dailyFocusMinutes[todayKey] ?? 0;

      debugPrint('📅 오늘($todayKey) 집중 시간: ${todayMinutes}분');

      // 4. 계산된 통계를 Firebase User 문서에 저장
      final updateResult = await _authRepository.updateUserFocusStats(
        userId: userId,
        stats: stats,
      );

      if (updateResult case Error(:final failure)) {
        debugPrint('❌ 사용자 통계 업데이트 실패: $failure');
        return Error(failure);
      }

      debugPrint('✅ 타이머 종료 후 사용자 통계 업데이트 완료');
      return const Success(null);
    } catch (e, stackTrace) {
      debugPrint('❌ UpdateUserStatsAfterTimerUseCase 실행 중 오류: $e');
      debugPrint('Stack trace: $stackTrace');
      return Error(
        Failure(
          FailureType.unknown,
          '타이머 종료 후 통계 업데이트 중 오류가 발생했습니다: $e',
          cause: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// 백그라운드에서 통계 업데이트 (UI 블로킹 없이)
  Future<void> executeInBackground(String userId) async {
    // 백그라운드에서 실행하여 타이머 종료 응답을 지연시키지 않음
    Future.delayed(Duration.zero, () async {
      try {
        final result = await execute(userId);

        if (result case Error(:final failure)) {
          debugPrint('⚠️ 백그라운드 통계 업데이트 실패: ${failure.message}');
          // 백그라운드 작업 실패는 무시 (타이머 종료 자체에는 영향 없음)
        } else {
          debugPrint('✅ 백그라운드 통계 업데이트 성공');
        }
      } catch (e) {
        debugPrint('⚠️ 백그라운드 통계 업데이트 예외: $e');
        // 예외 발생해도 무시
      }
    });
  }
}
