// lib/auth/domain/model/summary.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'summary.freezed.dart';

@freezed
class Summary with _$Summary {
  const Summary({
    required this.allTimeTotalSeconds,
    required this.groupTotalSecondsMap,
    required this.last7DaysActivityMap,
    required this.currentStreakDays,
    this.lastActivityDate,
    this.longestStreakDays = 0,
  });

  final int allTimeTotalSeconds; // 전체 활동 시간 (초)
  final Map<String, int> groupTotalSecondsMap; // 그룹별 누적 시간
  final Map<String, int> last7DaysActivityMap; // 최근 7일 활동
  final int currentStreakDays; // 현재 연속 활동 일수
  final String? lastActivityDate; // 마지막 활동 날짜
  final int longestStreakDays; // 최장 연속 활동 일수

  // 헬퍼 메서드들
  int get totalHours => allTimeTotalSeconds ~/ 3600;
  int get totalMinutes => (allTimeTotalSeconds % 3600) ~/ 60;

  // 오늘 활동 시간 (초)
  int get todaySeconds {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return last7DaysActivityMap[today] ?? 0;
  }

  // 이번 주 총 활동 시간 (초)
  int get weekTotalSeconds {
    return last7DaysActivityMap.values.fold(0, (sum, seconds) => sum + seconds);
  }
}
