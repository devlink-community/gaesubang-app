// lib/core/utils/focus_stats_calculator.dart
import 'package:devlink_mobile_app/auth/data/dto/timer_activity_dto.dart';
import 'package:devlink_mobile_app/profile/domain/model/focus_time_stats.dart';

class FocusStatsCalculator {
  const FocusStatsCalculator._();

  /// 타이머 활동 로그를 기반으로 집중 통계 계산
  static FocusTimeStats calculateFromActivities(
    List<TimerActivityDto> activities,
  ) {
    // 총 집중 시간 계산
    int totalMinutes = 0;

    // 요일별 집중 시간 계산
    final Map<String, int> weeklyMinutes = {
      '월': 0,
      '화': 0,
      '수': 0,
      '목': 0,
      '금': 0,
      '토': 0,
      '일': 0,
    };

    // 활동 로그를 start/end 쌍으로 묶어서 집중 시간 계산
    for (int i = 0; i < activities.length; i++) {
      final activity = activities[i];

      if (activity.type == 'start' && i + 1 < activities.length) {
        final nextActivity = activities[i + 1];

        if (nextActivity.type == 'end') {
          // start와 end 사이의 시간 계산
          final startTime = activity.timestamp;
          final endTime = nextActivity.timestamp;

          if (startTime != null && endTime != null) {
            final duration = endTime.difference(startTime);
            final minutes = duration.inMinutes;

            totalMinutes += minutes;

            // 요일별 시간 추가
            final weekday = _getKoreanWeekday(startTime.weekday);
            weeklyMinutes[weekday] = (weeklyMinutes[weekday] ?? 0) + minutes;
          }
        }
      }
    }

    return FocusTimeStats(
      totalMinutes: totalMinutes,
      weeklyMinutes: weeklyMinutes,
    );
  }

  /// 특정 기간의 집중 시간 계산
  static int calculateFocusMinutesInPeriod(
    List<TimerActivityDto> activities,
    DateTime startDate,
    DateTime endDate,
  ) {
    int totalMinutes = 0;

    for (int i = 0; i < activities.length; i++) {
      final activity = activities[i];

      if (activity.type == 'start' && i + 1 < activities.length) {
        final nextActivity = activities[i + 1];

        if (nextActivity.type == 'end') {
          final startTime = activity.timestamp;
          final endTime = nextActivity.timestamp;

          if (startTime != null &&
              endTime != null &&
              startTime.isAfter(startDate) &&
              endTime.isBefore(endDate)) {
            final duration = endTime.difference(startTime);
            totalMinutes += duration.inMinutes;
          }
        }
      }
    }

    return totalMinutes;
  }

  /// 요일 숫자를 한글 요일로 변환
  static String _getKoreanWeekday(int weekday) {
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
        return '월';
    }
  }

  /// 오늘의 집중 시간 계산
  static int calculateTodayFocusMinutes(List<TimerActivityDto> activities) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return calculateFocusMinutesInPeriod(activities, startOfDay, endOfDay);
  }

  /// 이번 주 집중 시간 계산
  static int calculateWeeklyFocusMinutes(List<TimerActivityDto> activities) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final endOfWeek = startOfWeekDay.add(const Duration(days: 7));

    return calculateFocusMinutesInPeriod(activities, startOfWeekDay, endOfWeek);
  }
}
