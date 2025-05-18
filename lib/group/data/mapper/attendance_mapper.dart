import 'package:devlink_mobile_app/group/domain/model/attendance.dart';

import '../dto/attendance_dto_old.dart';

extension AttendanceDtoMapper on AttendanceDto {
  Attendance toModel() => Attendance(
    memberId: memberId,
    groupId: groupId,
    date: DateTime.parse(date),
    time: time,
  );
}

extension AttendanceDtoListMapper on List<AttendanceDto> {
  List<Attendance> toModelList() => map((e) => e.toModel()).toList();
}

extension AttendanceModelMapper on Attendance {
  AttendanceDto toDto() => AttendanceDto(
    date: date.toIso8601String().split('T')[0],
    memberId: memberId,
    groupId: groupId,
    time: time,
  );
}

extension MapToAttendanceDto on Map<String, dynamic> {
  AttendanceDto toAttendanceDto() => AttendanceDto.fromJson(this);
}
