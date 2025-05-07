import 'package:json_annotation/json_annotation.dart';

part 'timer_session_dto.g.dart';

@JsonSerializable()
class TimerSessionDto {
  const TimerSessionDto({
    this.id,
    this.groupId,
    this.userId,
    this.startTime,
    this.endTime,
    this.duration,
    this.isCompleted,
  });

  final String? id;
  final String? groupId;
  final String? userId;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? duration; // 초 단위로 저장
  final bool? isCompleted;

  factory TimerSessionDto.fromJson(Map<String, dynamic> json) =>
      _$TimerSessionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TimerSessionDtoToJson(this);
}
