import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/model/member.dart';

class AttendanceState {
  final Map<String, Color> attendanceStatus;
  final AsyncValue<void> loading;
  final DateTime selectedDate;
  final DateTime displayedMonth;
  final List<Member> members;

  const AttendanceState({
    this.attendanceStatus = const {},
    this.loading = const AsyncLoading(),
    required this.selectedDate,
    required this.displayedMonth,
    this.members = const [],
  });

  AttendanceState copyWith({
    Map<String, Color>? attendanceStatus,
    AsyncValue<void>? loading,
    DateTime? selectedDate,
    DateTime? displayedMonth,
    List<Member>? members,
  }) {
    return AttendanceState(
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      loading: loading ?? this.loading,
      selectedDate: selectedDate ?? this.selectedDate,
      displayedMonth: displayedMonth ?? this.displayedMonth,
      members: members ?? this.members,
    );
  }
}