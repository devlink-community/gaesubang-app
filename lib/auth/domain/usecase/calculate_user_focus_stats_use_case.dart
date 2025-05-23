// lib/auth/domain/usecase/calculate_user_focus_stats_use_case.dart
import 'package:devlink_mobile_app/auth/domain/model/user_focus_stats.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/attendance.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';
import 'package:flutter/foundation.dart';

class CalculateUserFocusStatsUseCase {
  final AuthRepository _authRepository;
  final GroupRepository _groupRepository;

  CalculateUserFocusStatsUseCase({
    required AuthRepository authRepository,
    required GroupRepository groupRepository,
  }) : _authRepository = authRepository,
       _groupRepository = groupRepository;

  /// 사용자가 참여한 모든 그룹의 출석 데이터를 합산해서 통계 계산
  Future<Result<UserFocusStats>> execute(String userId) async {
    try {
      debugPrint('🔍 CalculateUserFocusStatsUseCase: 사용자 통계 계산 시작');
      debugPrint('🔍 userId: $userId');

      // 1. 사용자 정보 조회 (참여 그룹 목록 포함)
      final userResult = await _authRepository.getUserProfile(userId);
      if (userResult case Error(:final failure)) {
        debugPrint('❌ 사용자 정보 조회 실패: $failure');
        return Error(failure);
      }

      final user = (userResult as Success).data;
      final joinedGroupIds =
          user.joinedGroups
              .map((group) => group.groupId)
              .where((id) => id != null)
              .cast<String>()
              .toList();

      debugPrint('✅ 사용자 참여 그룹: ${joinedGroupIds.length}개');

      if (joinedGroupIds.isEmpty) {
        // 참여한 그룹이 없으면 빈 통계 반환
        debugPrint('📊 참여한 그룹이 없어서 빈 통계 반환');
        return Success(UserFocusStats.empty());
      }

      // 2. 모든 그룹의 출석 데이터 수집 (최근 3개월)
      final allAttendances = await _fetchAllUserAttendances(
        userId,
        joinedGroupIds,
      );

      debugPrint('📊 총 출석 데이터: ${allAttendances.length}개');

      // 3. 통계 계산
      final stats = _calculateStatsFromAttendances(allAttendances);

      debugPrint('✅ 사용자 통계 계산 완료');
      debugPrint('📊 총 집중시간: ${stats.totalFocusMinutes}분');
      debugPrint('📅 이번 주: ${stats.weeklyFocusMinutes}분');
      debugPrint('🔥 연속 학습일: ${stats.streakDays}일');
      debugPrint('📊 일별 데이터: ${stats.dailyFocusMinutes.length}개 항목');

      return Success(stats);
    } catch (e, stackTrace) {
      debugPrint('❌ CalculateUserFocusStatsUseCase 실행 중 오류: $e');
      debugPrint('Stack trace: $stackTrace');
      return Error(
        Failure(
          FailureType.unknown,
          '사용자 통계 계산 중 오류가 발생했습니다: $e',
          cause: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// 모든 그룹에서 사용자의 출석 데이터 수집
  Future<List<Attendance>> _fetchAllUserAttendances(
    String userId,
    List<String> groupIds,
  ) async {
    final allAttendances = <Attendance>[];
    final now = DateTime.now();

    // 각 그룹의 최근 3개월 데이터 수집
    for (final groupId in groupIds) {
      for (int i = 0; i < 3; i++) {
        final targetDate = DateTime(now.year, now.month - i, 1);
        final attendances = await _fetchGroupAttendances(
          groupId,
          targetDate.year,
          targetDate.month,
        );

        // 해당 사용자의 출석 데이터만 필터링
        final userAttendances =
            attendances
                .where((attendance) => attendance.memberId == userId)
                .toList();

        allAttendances.addAll(userAttendances);
      }
    }

    // 날짜순 정렬 (최신순)
    allAttendances.sort((a, b) => b.date.compareTo(a.date));

    return allAttendances;
  }

  /// 특정 그룹의 특정 월 출석 데이터 안전하게 조회
  Future<List<Attendance>> _fetchGroupAttendances(
    String groupId,
    int year,
    int month,
  ) async {
    try {
      final result = await _groupRepository.getAttendancesByMonth(
        groupId,
        year,
        month,
      );

      if (result case Success(:final data)) {
        return data;
      } else {
        debugPrint('⚠️ 그룹 $groupId의 $year-$month 출석 데이터 조회 실패');
        return <Attendance>[];
      }
    } catch (e) {
      debugPrint('⚠️ 그룹 $groupId의 $year-$month 출석 데이터 조회 중 오류: $e');
      return <Attendance>[];
    }
  }

  /// 출석 데이터로부터 UserFocusStats 계산
  UserFocusStats _calculateStatsFromAttendances(List<Attendance> attendances) {
    debugPrint('🔍 출석 데이터 기반 통계 계산 시작');
    debugPrint('📋 총 출석 데이터: ${attendances.length}개');

    // 1. 일별 데이터 계산
    final dailyFocusMinutes = <String, int>{};

    // 📌 출석 데이터 상세 로그
    attendances.forEach((attendance) {
      debugPrint(
        '  → 출석 데이터: ${UserFocusStats.formatDateKey(attendance.date)}, ${attendance.timeInMinutes}분, 그룹: ${attendance.groupId}',
      );
    });

    for (final attendance in attendances) {
      if (attendance.timeInMinutes <= 0) {
        debugPrint(
          '  ⚠️ 출석 데이터 무시됨 (시간 <= 0): ${UserFocusStats.formatDateKey(attendance.date)}',
        );
        continue;
      }

      final dateKey = UserFocusStats.formatDateKey(attendance.date);
      dailyFocusMinutes[dateKey] =
          (dailyFocusMinutes[dateKey] ?? 0) + attendance.timeInMinutes;

      debugPrint(
        '  ✅ 출석 데이터 추가: $dateKey, +${attendance.timeInMinutes}분, 그룹: ${attendance.groupId}',
      );
    }

    // 📌 일별 데이터 결과 로그
    debugPrint('📊 일별 데이터 계산 결과:');
    if (dailyFocusMinutes.isEmpty) {
      debugPrint('  ⚠️ 일별 데이터가 비어있습니다!');
    } else {
      dailyFocusMinutes.forEach((date, minutes) {
        debugPrint('  → $date: $minutes분');
      });
    }

    // 2. 총 집중시간 계산
    final totalMinutes = dailyFocusMinutes.values.fold<int>(
      0,
      (sum, minutes) => sum + minutes,
    );

    debugPrint('📊 총 집중시간: $totalMinutes분');

    // 3. 이번 주 집중시간 계산 (최근 7일)
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1)); // 이번 주 월요일
    final weekStartDate = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    int weeklyMinutes = 0;
    for (int i = 0; i < 7; i++) {
      final date = weekStartDate.add(Duration(days: i));
      final dateKey = UserFocusStats.formatDateKey(date);
      final dayMinutes = dailyFocusMinutes[dateKey] ?? 0;
      weeklyMinutes += dayMinutes;

      debugPrint(
        '  → 주간 계산: ${_getWeekdayName(date.weekday)} ($dateKey): $dayMinutes분',
      );
    }

    debugPrint('📊 이번 주 집중시간: $weeklyMinutes분');

    // 4. 연속 학습일 계산
    final streakDays = _calculateStreakDays(dailyFocusMinutes);

    debugPrint('📊 연속 학습일: $streakDays일');

    return UserFocusStats(
      totalFocusMinutes: totalMinutes,
      weeklyFocusMinutes: weeklyMinutes,
      streakDays: streakDays,
      lastUpdated: DateTime.now(),
      dailyFocusMinutes: dailyFocusMinutes,
    );
  }

  /// 연속 학습일 계산
  int _calculateStreakDays(Map<String, int> dailyData) {
    debugPrint('🔍 연속 학습일 계산 시작');

    if (dailyData.isEmpty) {
      debugPrint('  ⚠️ 일별 데이터가 비어있어 연속 학습일은 0일');
      return 0;
    }

    // 날짜 키를 정렬 (최신순)
    final sortedDates = dailyData.keys.toList()..sort((a, b) => b.compareTo(a));

    debugPrint('  📅 정렬된 날짜: $sortedDates');

    // 최소 학습 시간 기준 (예: 1분 이상) - 💥 5분→1분으로 수정
    const minStudyMinutes = 1;

    // 유효한 학습일만 필터링
    final validDates =
        sortedDates
            .where((dateKey) {
              final minutes = dailyData[dateKey] ?? 0;
              final isValid = minutes >= minStudyMinutes;
              debugPrint(
                '  → $dateKey: $minutes분 (${isValid ? "유효" : "유효하지 않음"})',
              );
              return isValid;
            })
            .map((dateKey) => DateTime.parse(dateKey))
            .toList();

    if (validDates.isEmpty) {
      debugPrint('  ⚠️ 유효한 학습일이 없어 연속 학습일은 0일');
      return 0;
    }

    debugPrint('  📅 유효한 학습일: ${validDates.length}일');

    // 오늘 기준으로 연속일 계산
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    debugPrint('  📅 오늘 날짜: ${UserFocusStats.formatDateKey(todayDateOnly)}');

    int streak = 0;
    DateTime checkDate = todayDateOnly;

    // 오늘부터 거꾸로 검사
    for (int i = 0; i < 100; i++) {
      // 안전장치: 최대 100일까지만 확인
      final checkDateKey = UserFocusStats.formatDateKey(checkDate);
      final minutes = dailyData[checkDateKey] ?? 0;

      debugPrint('  → 확인일: $checkDateKey, 집중시간: $minutes분');

      if (minutes >= minStudyMinutes) {
        streak++;
        debugPrint('  ✅ 연속일 증가: $streak일');
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        debugPrint('  ❌ 연속 끊김: $checkDateKey에 집중 기록 없음');
        break; // 연속이 끊기면 종료
      }
    }

    debugPrint('📊 최종 연속 학습일: $streak일');

    return streak;
  }

  // 요일 이름 가져오기 헬퍼 메서드
  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '?';
    }
  }
}
