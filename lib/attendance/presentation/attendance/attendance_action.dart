import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/model/group.dart';

part 'attendance_action.freezed.dart';

@freezed
sealed class AttendanceAction with _$AttendanceAction {
  const factory AttendanceAction.load() = LoadAttendance;
  const factory AttendanceAction.selectGroup(Group group) = SelectGroup;
  const factory AttendanceAction.selectDate(DateTime date) = SelectDate;
  const factory AttendanceAction.previousMonth() = PreviousMonth;
  const factory AttendanceAction.nextMonth() = NextMonth;
}
