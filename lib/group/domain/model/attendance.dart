import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance.freezed.dart';

@freezed
class Attendance with _$Attendance {
  const Attendance({
    required this.memberId,
    required this.date,
    required this.time,
  });

  final String memberId;
  final DateTime date;
  final int time;
}