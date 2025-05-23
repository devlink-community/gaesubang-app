// lib/auth/domain/model/user_focus_stats.dart
import 'package:flutter/cupertino.dart';

import '../../../profile/domain/model/focus_time_stats.dart';

class UserFocusStats {
  const UserFocusStats({
    required this.totalFocusMinutes,
    required this.weeklyFocusMinutes,
    required this.streakDays,
    this.lastUpdated,
    this.dailyFocusMinutes = const {}, // 🆕 일별 데이터 추가
  });

  /// 총 집중시간 (분)
  final int totalFocusMinutes;

  /// 이번 주 집중시간 (분)
  final int weeklyFocusMinutes;

  /// 연속 학습일
  final int streakDays;

  /// 통계 업데이트 시간
  final DateTime? lastUpdated;

  /// 🆕 날짜별 상세 집중 시간 (YYYY-MM-DD -> 분)
  /// 예: {"2025-05-23": 25, "2025-05-22": 30}
  final Map<String, int> dailyFocusMinutes;

  /// 총 집중시간을 시간:분 형식으로 포맷
  String get formattedTotalTime {
    final hours = totalFocusMinutes ~/ 60;
    final minutes = totalFocusMinutes % 60;

    if (hours > 0) {
      return '${hours}시간 ${minutes}분';
    } else {
      return '${minutes}분';
    }
  }

  /// 이번 주 집중시간을 시간:분 형식으로 포맷
  String get formattedWeeklyTime {
    final hours = weeklyFocusMinutes ~/ 60;
    final minutes = weeklyFocusMinutes % 60;

    if (hours > 0) {
      return '${hours}시간 ${minutes}분';
    } else {
      return '${minutes}분';
    }
  }

  /// 유효한 통계 데이터인지 확인
  bool get hasValidData => totalFocusMinutes > 0;

  /// 🆕 오늘 집중 시간 가져오기
  int get todayMinutes {
    final today = DateTime.now();
    final todayKey = formatDateKey(today);
    return dailyFocusMinutes[todayKey] ?? 0;
  }

  /// 🆕 특정 날짜의 집중 시간 가져오기
  int getMinutesForDate(DateTime date) {
    final dateKey = formatDateKey(date);
    return dailyFocusMinutes[dateKey] ?? 0;
  }

  /// 🆕 날짜를 키 형식으로 변환 (YYYY-MM-DD)
  /// static 메서드로 변경하여 모든 곳에서 접근 가능하게 함
  static String formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Firebase 저장용 Map으로 변환
  Map<String, dynamic> toFirebaseMap() {
    debugPrint('🔄 UserFocusStats.toFirebaseMap() 호출');
    debugPrint('  - totalFocusMinutes: ${totalFocusMinutes}분');
    debugPrint('  - weeklyFocusMinutes: ${weeklyFocusMinutes}분');
    debugPrint('  - streakDays: ${streakDays}일');
    debugPrint('  - dailyFocusMinutes: ${dailyFocusMinutes.length}개 항목');

    // 일별 데이터 로그
    if (dailyFocusMinutes.isNotEmpty) {
      dailyFocusMinutes.forEach((date, minutes) {
        debugPrint('    → $date: $minutes분');
      });
    } else {
      debugPrint('    ⚠️ 일별 데이터가 비어 있습니다!');
    }

    final map = {
      'totalFocusMinutes': totalFocusMinutes,
      'weeklyFocusMinutes': weeklyFocusMinutes,
      'streakDays': streakDays,
      'lastStatsUpdated': (lastUpdated ?? DateTime.now()).toIso8601String(),
      'dailyFocusMinutes': dailyFocusMinutes, // 🆕 일별 데이터 추가
    };

    debugPrint('  → 변환된 Map: $map');
    return map;
  }

  /// 🆕 FocusTimeStats로 변환
  FocusTimeStats toFocusTimeStats() {
    // 요일별 데이터 계산
    final weeklyMap = _calculateWeeklyMap();

    return FocusTimeStats(
      totalMinutes: totalFocusMinutes,
      weeklyMinutes: weeklyMap,
      dailyMinutes: Map<String, int>.from(dailyFocusMinutes),
    );
  }

  /// 🆕 일별 데이터에서 요일별 Map 생성
  Map<String, int> _calculateWeeklyMap() {
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
      final dateKey = formatDateKey(date);
      final minutes = dailyFocusMinutes[dateKey] ?? 0;

      final weekdayIndex = (date.weekday - 1) % 7; // 월요일=0, 일요일=6
      weeklyMap[weekdays[weekdayIndex]] = minutes;
    }

    return weeklyMap;
  }

  /// Firebase Map에서 UserFocusStats 생성
  factory UserFocusStats.fromFirebaseMap(Map<String, dynamic> data) {
    // 일별 데이터 처리
    final rawDailyData = data['dailyFocusMinutes'];
    final dailyFocusMinutes = <String, int>{};

    if (rawDailyData != null && rawDailyData is Map) {
      rawDailyData.forEach((key, value) {
        if (value is num) {
          dailyFocusMinutes[key.toString()] = value.toInt();
        }
      });
    }

    return UserFocusStats(
      totalFocusMinutes: data['totalFocusMinutes'] as int? ?? 0,
      weeklyFocusMinutes: data['weeklyFocusMinutes'] as int? ?? 0,
      streakDays: data['streakDays'] as int? ?? 0,
      lastUpdated:
          data['lastStatsUpdated'] != null
              ? DateTime.tryParse(data['lastStatsUpdated'] as String)
              : null,
      dailyFocusMinutes: dailyFocusMinutes,
    );
  }

  /// 🆕 특정 날짜의 시간 추가
  UserFocusStats addMinutesForDate(DateTime date, int minutes) {
    if (minutes <= 0) return this;

    final dateKey = formatDateKey(date);
    final newDailyMinutes = Map<String, int>.from(dailyFocusMinutes);
    newDailyMinutes[dateKey] = (newDailyMinutes[dateKey] ?? 0) + minutes;

    // 주간 합계 재계산 (이번 주에 속하는 날짜인지 확인)
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    int newWeeklyMinutes = weeklyFocusMinutes;
    if (date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
        date.isBefore(weekEnd.add(const Duration(days: 1)))) {
      newWeeklyMinutes += minutes;
    }

    // 총 시간 증가
    final newTotalMinutes = totalFocusMinutes + minutes;

    return UserFocusStats(
      totalFocusMinutes: newTotalMinutes,
      weeklyFocusMinutes: newWeeklyMinutes,
      streakDays: _calculateStreakDays(newDailyMinutes),
      lastUpdated: DateTime.now(),
      dailyFocusMinutes: newDailyMinutes,
    );
  }

  /// 🆕 연속 학습일 재계산
  int _calculateStreakDays(Map<String, int> dailyData) {
    if (dailyData.isEmpty) return 0;

    // 날짜 키를 정렬 (최신순)
    final sortedDates = dailyData.keys.toList()..sort((a, b) => b.compareTo(a));

    // 최소 학습 시간 기준 (예: 5분 이상)
    const minStudyMinutes = 5;

    // 유효한 학습일만 필터링
    final validDates =
        sortedDates
            .where((dateKey) => (dailyData[dateKey] ?? 0) >= minStudyMinutes)
            .map((dateKey) => DateTime.parse(dateKey))
            .toList();

    if (validDates.isEmpty) return 0;

    // 오늘 기준으로 연속일 계산
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    int streak = 0;
    DateTime checkDate = todayDateOnly;

    for (int i = 0; i < 100; i++) {
      // 안전장치: 최대 100일까지만 확인
      final checkDateKey = formatDateKey(checkDate);
      final minutes = dailyData[checkDateKey] ?? 0;

      if (minutes >= minStudyMinutes) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break; // 연속이 끊기면 종료
      }
    }

    return streak;
  }

  /// 빈 통계 생성
  factory UserFocusStats.empty() {
    return const UserFocusStats(
      totalFocusMinutes: 0,
      weeklyFocusMinutes: 0,
      streakDays: 0,
      dailyFocusMinutes: {},
    );
  }

  /// copyWith 메서드
  UserFocusStats copyWith({
    int? totalFocusMinutes,
    int? weeklyFocusMinutes,
    int? streakDays,
    DateTime? lastUpdated,
    Map<String, int>? dailyFocusMinutes,
  }) {
    return UserFocusStats(
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      weeklyFocusMinutes: weeklyFocusMinutes ?? this.weeklyFocusMinutes,
      streakDays: streakDays ?? this.streakDays,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      dailyFocusMinutes: dailyFocusMinutes ?? this.dailyFocusMinutes,
    );
  }

  @override
  String toString() {
    return 'UserFocusStats(totalFocusMinutes: $totalFocusMinutes, weeklyFocusMinutes: $weeklyFocusMinutes, streakDays: $streakDays, lastUpdated: $lastUpdated, dailyMinutes: ${dailyFocusMinutes.length}개)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UserFocusStats &&
            totalFocusMinutes == other.totalFocusMinutes &&
            weeklyFocusMinutes == other.weeklyFocusMinutes &&
            streakDays == other.streakDays &&
            lastUpdated == other.lastUpdated);
  }

  @override
  int get hashCode => Object.hash(
    totalFocusMinutes,
    weeklyFocusMinutes,
    streakDays,
    lastUpdated,
  );
}
