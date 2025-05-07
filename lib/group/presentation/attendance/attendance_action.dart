import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_action.freezed.dart';

@freezed
sealed class AttendanceAction with _$AttendanceAction {
  // 기능 액션
  const factory AttendanceAction.load(DateTime date) = LoadAttendance;
  const factory AttendanceAction.selectMember(String memberId) = SelectMember;

  // UI 액션
  const factory AttendanceAction.selectDate(DateTime date) = SelectDate;
  const factory AttendanceAction.previousMonth() = PreviousMonth;
  const factory AttendanceAction.nextMonth() = NextMonth;
}

extension AttendanceActionExtension on AttendanceAction {
  T process<T>({
    required T Function(LoadAttendance) load,
    required T Function(SelectMember) selectMember,
    required T Function(SelectDate) selectDate,
    required T Function(PreviousMonth) previousMonth,
    required T Function(NextMonth) nextMonth,
  }) {
    final action = this;

    if (action is LoadAttendance) {
      return load(action);
    } else if (action is SelectMember) {
      return selectMember(action);
    } else if (action is SelectDate) {
      return selectDate(action);
    } else if (action is PreviousMonth) {
      return previousMonth(action);
    } else if (action is NextMonth) {
      return nextMonth(action);
    }

    throw Exception('Unknown action type');
  }
}