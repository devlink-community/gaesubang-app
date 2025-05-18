import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_action.freezed.dart';

@freezed
sealed class AttendanceAction with _$AttendanceAction {
  // ID로 그룹 설정
  const factory AttendanceAction.setGroupId(String groupId) = SetGroupId;

  // 날짜 선택
  const factory AttendanceAction.selectDate(DateTime date) = SelectDate;

  // 월 변경 (이전/다음 월 이동)
  const factory AttendanceAction.changeMonth(DateTime month) = ChangeMonth;

  // 출석 데이터 로드 요청
  const factory AttendanceAction.loadAttendanceData() = LoadAttendanceData;
}
