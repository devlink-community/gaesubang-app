import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'attendance_state.freezed.dart';

@freezed
class AttendanceState with _$AttendanceState {
  const factory AttendanceState({
    @Default({}) Map<String, Color> attendanceStatus,
    @Default(AsyncLoading()) AsyncValue<void> loading,
    required DateTime selectedDate,
    required DateTime displayedMonth,
  }) = _AttendanceState;
}
