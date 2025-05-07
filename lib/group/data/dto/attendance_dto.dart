import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class AttendanceDto {
  const AttendanceDto({
    required this.date,
    required this.memberId,
    required this.time,
  });

  final String date;
  final String memberId;
  final int time;

  factory AttendanceDto.fromJson(Map<String, dynamic> json) => _$AttendanceDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceDtoToJson(this);
}