import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../domain/model/member_attendance.dart';

part 'attendance_state.freezed.dart';

@freezed
sealed class AttendanceState with _$AttendanceState {
  const factory AttendanceState({
    @Default(AsyncLoading()) AsyncValue<List<MemberAttendance>> attendances,
    String? selectedMemberId,
  }) = _AttendanceState;
}
