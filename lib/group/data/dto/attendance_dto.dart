// lib/group/data/dto/attendance_dto.dart
import 'package:json_annotation/json_annotation.dart';

part 'attendance_dto.g.dart';

@JsonSerializable()
class AttendanceDto {
  const AttendanceDto({
    this.groupId,
    this.userId,
    this.date,
    this.timeInSeconds,
  });

  final String? groupId;
  final String? userId;
  final String? date;
  final int? timeInSeconds;

  factory AttendanceDto.fromJson(Map<String, dynamic> json) =>
      _$AttendanceDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceDtoToJson(this);
}
