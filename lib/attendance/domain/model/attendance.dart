import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance.freezed.dart';

@freezed
class Attendance with _$Attendance {
  final String memberId;
  final DateTime date;
  final int time;

  const Attendance({
    required this.memberId,
    required this.date,
    required this.time,
  });


}