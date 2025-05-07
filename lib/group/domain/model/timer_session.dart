import 'package:freezed_annotation/freezed_annotation.dart';

part 'timer_session.freezed.dart';

@freezed
class TimerSession with _$TimerSession {
  const TimerSession({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.isCompleted,
  });

  final String id;
  final String groupId;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final int duration; // 초 단위
  final bool isCompleted;
}
