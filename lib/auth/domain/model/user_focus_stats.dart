// lib/auth/domain/model/user_focus_stats.dart
class UserFocusStats {
  const UserFocusStats({
    required this.totalFocusMinutes,
    required this.weeklyFocusMinutes,
    required this.streakDays,
    this.lastUpdated,
  });

  /// 총 집중시간 (분)
  final int totalFocusMinutes;

  /// 이번 주 집중시간 (분)
  final int weeklyFocusMinutes;

  /// 연속 학습일
  final int streakDays;

  /// 통계 업데이트 시간
  final DateTime? lastUpdated;

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

  /// Firebase 저장용 Map으로 변환
  Map<String, dynamic> toFirebaseMap() {
    return {
      'totalFocusMinutes': totalFocusMinutes,
      'weeklyFocusMinutes': weeklyFocusMinutes,
      'streakDays': streakDays,
      'lastStatsUpdated': (lastUpdated ?? DateTime.now()).toIso8601String(),
    };
  }

  /// Firebase Map에서 UserFocusStats 생성
  factory UserFocusStats.fromFirebaseMap(Map<String, dynamic> data) {
    return UserFocusStats(
      totalFocusMinutes: data['totalFocusMinutes'] as int? ?? 0,
      weeklyFocusMinutes: data['weeklyFocusMinutes'] as int? ?? 0,
      streakDays: data['streakDays'] as int? ?? 0,
      lastUpdated:
          data['lastStatsUpdated'] != null
              ? DateTime.tryParse(data['lastStatsUpdated'] as String)
              : null,
    );
  }

  /// 빈 통계 생성
  factory UserFocusStats.empty() {
    return const UserFocusStats(
      totalFocusMinutes: 0,
      weeklyFocusMinutes: 0,
      streakDays: 0,
    );
  }

  /// copyWith 메서드
  UserFocusStats copyWith({
    int? totalFocusMinutes,
    int? weeklyFocusMinutes,
    int? streakDays,
    DateTime? lastUpdated,
  }) {
    return UserFocusStats(
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      weeklyFocusMinutes: weeklyFocusMinutes ?? this.weeklyFocusMinutes,
      streakDays: streakDays ?? this.streakDays,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'UserFocusStats(totalFocusMinutes: $totalFocusMinutes, weeklyFocusMinutes: $weeklyFocusMinutes, streakDays: $streakDays, lastUpdated: $lastUpdated)';
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
