import 'package:freezed_annotation/freezed_annotation.dart';

part 'timer.freezed.dart';

@freezed
class Timer with _$Timer {
  const Timer({
    required this.memberId,
    required this.minTime,
    required this.totalTime,
  });

  final String memberId;
  final int minTime;
  final int totalTime;
}