import '../../domain/model/attendance.dart';
import '../dto/attendance_dto.dart';

extension AttendanceDtoMapper on AttendanceDto {
  Attendance toModel() => Attendance(
    memberId: memberId,
    date: DateTime.parse(date),
    time: time,
  );
}

extension AttendanceDtoListMapper on List<AttendanceDto> {
  List<Attendance> toModelList() => map((e) => e.toModel()).toList();
}
