import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';


class AttendanceState {
  final Map<String, Color> attendanceStatus;
  final AsyncValue<void> loading;
  final DateTime selectedDate;
  final DateTime displayedMonth;
  final String groupId;

  const AttendanceState({
    this.attendanceStatus = const {},
    this.loading = const AsyncLoading(),
    required this.selectedDate,
    required this.displayedMonth,
    required this.groupId,
  });

  AttendanceState copyWith({
    Map<String, Color>? attendanceStatus,
    AsyncValue<void>? loading,
    DateTime? selectedDate,
    DateTime? displayedMonth,
    String? groupId,
  }) {
    return AttendanceState(
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      loading: loading ?? this.loading,
      selectedDate: selectedDate ?? this.selectedDate,
      displayedMonth: displayedMonth ?? this.displayedMonth,
      groupId:  groupId ?? this.groupId,
    );
  }
}