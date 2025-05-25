// lib/auth/data/repository_impl/auth_activity_repository_impl.dart 수정
import 'package:devlink_mobile_app/auth/data/data_source/auth_data_source.dart';
import 'package:devlink_mobile_app/auth/data/mapper/summary_mapper.dart';
import 'package:devlink_mobile_app/auth/domain/model/summary.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_activity_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
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
  Future<Result<void>> updateSummaryForTimerActivity({
    required String userId,
    required String groupId,
    required int elapsedSeconds,
    required String dateKey,
  }) async {
    try {
      AppLogger.debug(
        '타이머 활동에 따른 Summary 업데이트 시작: userId=$userId, groupId=$groupId, seconds=$elapsedSeconds',
        tag: 'AuthActivityRepository',
      );

      // 1. 현재 사용자의 Summary 조회
      final summaryResult = await getUserSummary(userId);

      if (summaryResult is Error) {
        AppLogger.error(
          'Summary 조회 실패',
          tag: 'AuthActivityRepository',
          error: (summaryResult as Error).failure,
        );
        return summaryResult;
      }

      // 2. 기존 Summary 또는 새로운 Summary 생성
      final existingSummary = (summaryResult as Success<Summary?>).data;
      final updatedSummary = _updateSummaryWithTimerActivity(
        existingSummary,
        groupId,
        elapsedSeconds,
        dateKey,
      );

      // 3. 업데이트된 Summary 저장
      return await updateUserSummary(
        userId: userId,
        summary: updatedSummary,
      );
    } catch (e, st) {
      AppLogger.error(
        '타이머 활동에 따른 Summary 업데이트 실패',
        tag: 'AuthActivityRepository',
        error: e,
        stackTrace: st,
      );
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  /// 타이머 활동 정보로 Summary 업데이트하는 내부 메서드
  Summary _updateSummaryWithTimerActivity(
    Summary? existingSummary,
    String groupId,
    int elapsedSeconds,
    String dateKey,
  ) {
    // 기존 Summary가 없는 경우 새로 생성
    if (existingSummary == null) {
      return Summary(
        allTimeTotalSeconds: elapsedSeconds,
        groupTotalSecondsMap: {groupId: elapsedSeconds},
        last7DaysActivityMap: {dateKey: elapsedSeconds},
        currentStreakDays: 1, // 오늘 활동했으므로 1
        lastActivityDate: dateKey,
        longestStreakDays: 1,
      );
    }

    // 1. 전체 누적 시간 업데이트
    final newTotalSeconds =
        existingSummary.allTimeTotalSeconds + elapsedSeconds;

    // 2. 그룹별 누적 시간 업데이트
    final groupTotalSecondsMap = Map<String, int>.from(
      existingSummary.groupTotalSecondsMap,
    );
    final groupSeconds = groupTotalSecondsMap[groupId] ?? 0;
    groupTotalSecondsMap[groupId] = groupSeconds + elapsedSeconds;

    // 3. 최근 7일 활동 업데이트
    final last7DaysActivityMap = Map<String, int>.from(
      existingSummary.last7DaysActivityMap,
    );
    final dayActivity = last7DaysActivityMap[dateKey] ?? 0;
    last7DaysActivityMap[dateKey] = dayActivity + elapsedSeconds;

    // 7일이 지난 데이터 제거 (추가 구현 가능)
    // ...

    // 4. streak 업데이트 계산
    int newStreakDays = existingSummary.currentStreakDays;
    int newLongestStreak = existingSummary.longestStreakDays;

    // 이전 활동일과 오늘의 차이 계산
    int daysGap = 0;
    if (existingSummary.lastActivityDate != null) {
      try {
        final lastDate = DateTime.parse(existingSummary.lastActivityDate!);
        final today = DateTime.parse(dateKey);
        daysGap = today.difference(lastDate).inDays;
      } catch (e) {
        AppLogger.warning(
          '날짜 파싱 오류',
          tag: 'AuthActivityRepository',
          error: e,
        );
        daysGap = 1; // 기본값
      }
    }

    // streak 로직
    if (existingSummary.lastActivityDate == null || daysGap > 1) {
      // 처음 활동이거나 연속성이 끊김
      newStreakDays = 1;
    } else if (daysGap == 1) {
      // 어제 활동 이후 오늘 활동 (연속)
      newStreakDays += 1;
      // 최장 연속일 업데이트 확인
      if (newStreakDays > newLongestStreak) {
        newLongestStreak = newStreakDays;
      }
    } else if (daysGap == 0) {
      // 오늘 이미 활동했음 (streak 유지)
    }

    // 5. 업데이트된 Summary 반환
    return Summary(
      allTimeTotalSeconds: newTotalSeconds,
      groupTotalSecondsMap: groupTotalSecondsMap,
      last7DaysActivityMap: last7DaysActivityMap,
      currentStreakDays: newStreakDays,
      lastActivityDate: dateKey,
      longestStreakDays: newLongestStreak,
    );
  }
}
