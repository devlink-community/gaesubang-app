import '../../domain/model/member_attendance.dart';
import '../dto/timer_dto.dart';

extension TimerDtoToMemberAttendanceMapper on TimerDto {
  MemberAttendance toAttendance() {
    final percentage = totalTime >= 240
        ? 80
        : totalTime >= 120
        ? 50
        : totalTime >= 60
        ? 20
        : 0;

    return MemberAttendance(
      memberId: memberId,
      totalTime: totalTime,
      percentage: percentage,
    );
  }
}

extension TimerDtoListToAttendanceListMapper on List<TimerDto> {
  List<MemberAttendance> toAttendanceList() => map((e) => e.toAttendance()).toList();
}