import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_action.freezed.dart';

@freezed
sealed class AttendanceAction with _$AttendanceAction {
  const factory AttendanceAction.load(DateTime date) = LoadAttendance;
  const factory AttendanceAction.selectMember(String memberId) = SelectMember;
}