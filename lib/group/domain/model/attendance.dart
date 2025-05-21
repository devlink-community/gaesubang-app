// lib/group/domain/model/attendance.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance.freezed.dart';

@freezed
class Attendance with _$Attendance {
  const Attendance({
    required this.groupId,
    required this.memberId,
    required this.memberName,
    this.profileUrl,
    required this.date,
    required this.timeInMinutes,
  });

  /// 그룹 ID
  final String groupId;

  /// 멤버 ID
  final String memberId;

  /// 멤버 이름 (UI 표시용)
  final String memberName;

  /// 멤버 프로필 이미지 URL
  final String? profileUrl;

  /// 출석 날짜
  final DateTime date;

  /// 활동 시간 (분 단위)
  final int timeInMinutes;
}
