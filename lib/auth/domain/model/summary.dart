// lib/auth/domain/model/summary.dart
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:devlink_mobile_app/group/domain/model/timer_activity_type.dart'; // 추가: TimerActivityType import
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
    this.lastTimerState, // 추가: 마지막 타이머 상태
    this.lastTimerGroupId, // 추가: 마지막 타이머 그룹 ID
    this.lastTimerTimestamp, // 추가: 마지막 타이머 활동 시간
  });

  final int allTimeTotalSeconds; // 전체 활동 시간 (초)
  final Map<String, int> groupTotalSecondsMap; // 그룹별 누적 시간
  final Map<String, int> last7DaysActivityMap; // 최근 7일 활동
  final int currentStreakDays; // 현재 연속 활동 일수
  final String? lastActivityDate; // 마지막 활동 날짜
  final int longestStreakDays; // 최장 연속 활동 일수
  final TimerActivityType? lastTimerState; // 추가: 마지막 타이머 상태
  final String? lastTimerGroupId; // 추가: 마지막 타이머 그룹 ID
  final DateTime? lastTimerTimestamp; // 추가: 마지막 타이머 활동 시간

  // 헬퍼 메서드들
  int get totalHours => allTimeTotalSeconds ~/ 3600;
  int get totalMinutes => (allTimeTotalSeconds % 3600) ~/ 60;

  // 오늘 활동 시간 (초)
  int get todaySeconds {
    final today = TimeFormatter.getDateKeyInSeoul();
    return last7DaysActivityMap[today] ?? 0;
  }

  // 이번 주 총 활동 시간 (초)
  int get weekTotalSeconds {
    return last7DaysActivityMap.values.fold(0, (sum, seconds) => sum + seconds);
  }

  // 추가: 타이머가 활성 상태인지 확인
  bool get isTimerActive =>
      lastTimerState == TimerActivityType.start ||
      lastTimerState == TimerActivityType.resume;

  // 추가: 타이머가 일시정지 상태인지 확인
  bool get isTimerPaused => lastTimerState == TimerActivityType.pause;

  // 추가: 타이머가 종료 상태인지 확인
  bool get isTimerEnded => lastTimerState == TimerActivityType.end;
}
