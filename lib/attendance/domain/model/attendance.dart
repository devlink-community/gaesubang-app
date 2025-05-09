import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance.freezed.dart';

@freezed
class Attendance with _$Attendance {
  const Attendance({
    required this.memberId,
    required this.groupId,
    required this.date,
    required this.time,
  });

  final String memberId;
  final String groupId;
  final DateTime date;
  final int time;
}