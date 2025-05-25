// lib/group/domain/model/group_member.dart
import 'package:devlink_mobile_app/group/domain/model/timer_activity_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_member.freezed.dart';

@freezed
class GroupMember with _$GroupMember {
  const GroupMember({
    required this.id,
    required this.userId,
    required this.userName,
    this.profileUrl,
    required this.role,
    required this.joinedAt,
    required this.timerState,
    this.timerStartAt,
    this.timerLastUpdatedAt,
    required this.timerElapsed,
    required this.timerTodayDuration,
    required this.timerMonthlyDurations,
    required this.timerTotalDuration,
    this.timerPauseExpiryTime,
  });

  final String id;
  final String userId;
  final String userName;
  final String? profileUrl;
  final String role; // "owner", "member"
  final DateTime joinedAt;

  // 타이머 상태 필드 - TimerActivityType 사용
  final TimerActivityType timerState;
  final DateTime? timerStartAt;
  final DateTime? timerLastUpdatedAt;
  final int timerElapsed;
  final int timerTodayDuration;
  final Map<String, int> timerMonthlyDurations;
  final int timerTotalDuration;
  final DateTime? timerPauseExpiryTime;

  /// 타이머 상태가 활성화 상태인지 확인
  bool get isActive =>
      timerState == TimerActivityType.start ||
      timerState == TimerActivityType.resume;

  /// 타이머 상태가 일시정지 상태인지 확인
  bool get isPaused => timerState == TimerActivityType.pause;

  /// 타이머 상태가 종료 상태인지 확인
  bool get isEnded => timerState == TimerActivityType.end;

  /// 현재 경과 시간 계산 (초)
  int get currentElapsedSeconds {
    if (!isActive || timerStartAt == null) return timerElapsed;

    final now = DateTime.now();
    return timerElapsed + now.difference(timerStartAt!).inSeconds;
  }

  /// 현재 경과 시간 계산 (분)
  int get currentElapsedMinutes => (currentElapsedSeconds / 60).floor();
}
