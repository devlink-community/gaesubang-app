import 'package:freezed_annotation/freezed_annotation.dart';

part 'member_attendance.freezed.dart';

// 그룹 출석부
@freezed
class MemberAttendance with _$MemberAttendance {
  const MemberAttendance({
    required this.memberId,
    required this.totalTime,
    required this.percentage,
  });

  final String memberId;
  final int totalTime;
  final int percentage;
}