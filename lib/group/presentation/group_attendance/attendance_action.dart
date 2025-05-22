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

  // 🔧 새로 추가: 로케일 초기화
  const factory AttendanceAction.initializeLocale() = InitializeLocale;

  // 🔧 새로 추가: 날짜별 출석 정보 버텀 시트 표시
  const factory AttendanceAction.showDateAttendanceBottomSheet(DateTime date) =
      ShowDateAttendanceBottomSheet;
}
