// lib/group/domain/model/group_member_activity.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_member_activity.freezed.dart';

@freezed
class GroupMemberActivity with _$GroupMemberActivity {
  const GroupMemberActivity({
    required this.state,
    this.startAt,
    required this.lastUpdatedAt,
    required this.elapsed,
    required this.todayDuration,
    required this.monthlyDurations,
    required this.totalDuration,
  });

  /// 타이머 상태 ("running", "paused", "idle")
  final String state;

  /// 현재 세션 시작 시간 (running 상태일 때만 유효)
  final DateTime? startAt;

  /// 마지막 업데이트 시간
  final DateTime lastUpdatedAt;

  /// 현재 세션 누적 초 (paused 상태일 때)
  final int elapsed;

  /// 오늘 총 누적 시간 (초)
  final int todayDuration;

  /// 일자별 누적 시간 (초)
  final Map<String, int> monthlyDurations;

  /// 전체 누적 시간 (초)
  final int totalDuration;

  /// 현재 활성화 상태 여부
  bool get isActive => state == 'running' || state == 'resume';

  /// 현재 일시정지 상태 여부
  bool get isPaused => state == 'paused';

  /// 현재 아이들 상태 여부
  bool get isIdle => state == 'idle';

  /// 현재 경과 시간 계산 (초)
  int get currentElapsedSeconds {
    if (!isActive || startAt == null) return elapsed;

    final now = DateTime.now();
    return elapsed + now.difference(startAt!).inSeconds;
  }

  /// 현재 경과 시간 계산 (분)
  int get currentElapsedMinutes => (currentElapsedSeconds / 60).floor();
}
