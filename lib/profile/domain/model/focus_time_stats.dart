// lib/profile/domain/model/focus_time_stats.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'focus_time_stats.freezed.dart';

@freezed
class FocusTimeStats with _$FocusTimeStats {
  const FocusTimeStats({
    required this.totalMinutes,
    required this.weeklyMinutes,
    required this.dailyMinutes, // 🆕 일별 상세 데이터 추가
  });

  /// 총 집중 시간(분)
  final int totalMinutes;

  /// 요일별 집중 시간 통계 (차트용)
  final Map<String, int> weeklyMinutes;

  /// 🆕 날짜별 상세 집중 시간 (YYYY-MM-DD -> 분)
  /// 예: {"2025-05-23": 25, "2025-05-22": 30}
  final Map<String, int> dailyMinutes;

  /// 🆕 이번 주 총 집중 시간 계산
  int get thisWeekTotalMinutes {
    return weeklyMinutes.values.fold(0, (sum, minutes) => sum + minutes);
  }

  /// 🆕 오늘 집중 시간 가져오기
  int get todayMinutes {
    final today = DateTime.now();
    final todayKey = _formatDateKey(today);
    return dailyMinutes[todayKey] ?? 0;
  }

  /// 🆕 특정 날짜의 집중 시간 가져오기
  int getMinutesForDate(DateTime date) {
    final dateKey = _formatDateKey(date);
    return dailyMinutes[dateKey] ?? 0;
  }

  /// 🆕 이번 주 날짜 범위의 데이터만 추출하여 요일별 Map 생성
  static Map<String, int> calculateWeeklyFromDaily(
    Map<String, int> dailyMinutes,
  ) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1)); // 이번 주 월요일

    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weeklyMap = <String, int>{};

    // 각 요일별로 초기화
    for (final day in weekdays) {
      weeklyMap[day] = 0;
    }

    // 이번 주 7일간의 데이터 합산
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateKey = _formatDateKey(date);
      final minutes = dailyMinutes[dateKey] ?? 0;

      final weekdayIndex = (date.weekday - 1) % 7; // 월요일=0, 일요일=6
      weeklyMap[weekdays[weekdayIndex]] = minutes;
    }

    return weeklyMap;
  }

  /// 🆕 빈 통계 생성 (데이터가 없을 때)
  factory FocusTimeStats.empty() {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final emptyWeekly = <String, int>{};
    for (final day in weekdays) {
      emptyWeekly[day] = 0;
    }

    return FocusTimeStats(
      totalMinutes: 0,
      weeklyMinutes: emptyWeekly,
      dailyMinutes: const <String, int>{},
    );
  }

  /// 🆕 날짜를 키 형식으로 변환 (YYYY-MM-DD)
  static String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 🆕 특정 날짜에 시간 추가
  FocusTimeStats addMinutesForDate(DateTime date, int minutes) {
    final dateKey = _formatDateKey(date);
    final newDailyMinutes = Map<String, int>.from(dailyMinutes);
    newDailyMinutes[dateKey] = (newDailyMinutes[dateKey] ?? 0) + minutes;

    // 요일별 데이터도 재계산
    final newWeeklyMinutes = calculateWeeklyFromDaily(newDailyMinutes);

    // 총 시간도 재계산
    final newTotalMinutes = newDailyMinutes.values.fold(
      0,
      (sum, mins) => sum + mins,
    );

    return copyWith(
      totalMinutes: newTotalMinutes,
      weeklyMinutes: newWeeklyMinutes,
      dailyMinutes: newDailyMinutes,
    );
  }

  /// 🆕 일별 데이터에서 FocusTimeStats 생성
  factory FocusTimeStats.fromDailyData(Map<String, int> dailyMinutes) {
    final weeklyMinutes = calculateWeeklyFromDaily(dailyMinutes);
    final totalMinutes = dailyMinutes.values.fold(0, (sum, mins) => sum + mins);

    return FocusTimeStats(
      totalMinutes: totalMinutes,
      weeklyMinutes: weeklyMinutes,
      dailyMinutes: dailyMinutes,
    );
  }
}
