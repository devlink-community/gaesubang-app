import 'package:freezed_annotation/freezed_annotation.dart';

part 'timer_dto.g.dart';


@JsonSerializable(explicitToJson: true)
class TimerDto {
  const TimerDto({
    required this.memberId,
    required this.minTime,
    required this.totalTime,
  });

  final String memberId;
  final int minTime;
  final int totalTime;

  factory TimerDto.fromJson(Map<String, dynamic> json) => _$TimerDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TimerDtoToJson(this);
}