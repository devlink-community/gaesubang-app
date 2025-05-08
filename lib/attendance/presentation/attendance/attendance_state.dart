import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/member.dart';

part 'attendance_state.freezed.dart';

@freezed
class AttendanceState with _$AttendanceState {
  const AttendanceState({
    this.attendanceStatus = const {},
    this.loading = const AsyncLoading(),
    required this.selectedDate,
    required this.displayedMonth,
    this.members = const [],
  });

  final Map<String, Color> attendanceStatus;
  final AsyncValue<void> loading;
  final DateTime selectedDate;
  final DateTime displayedMonth;
  final List<Member> members;
}
