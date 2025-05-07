import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/material.dart';

import 'attendance_state.dart';

part 'attendance_notifier.g.dart';

@riverpod
class AttendanceNotifier extends _$AttendanceNotifier {
  @override
  AttendanceState build() {
    final now = DateTime.now();
    return AttendanceState(
      selectedDate: now,
      displayedMonth: DateTime(now.year, now.month, 1),
    );
  }

  void onDateSelected(DateTime date) {
    final dateKey = _format(date);
    final updatedStatus = Map<String, Color>.from(state.attendanceStatus);

    if (updatedStatus.containsKey(dateKey)) {
      updatedStatus.remove(dateKey);
    } else {
      updatedStatus[dateKey] = const Color(0xFFA5A6F6); // 임시 색상
    }

    state = state.copyWith(
      selectedDate: date,
      attendanceStatus: updatedStatus,
    );
  }

  void onPreviousMonth() {
    final prevMonth = DateTime(state.displayedMonth.year, state.displayedMonth.month - 1, 1);
    state = state.copyWith(displayedMonth: prevMonth);
  }

  void onNextMonth() {
    final nextMonth = DateTime(state.displayedMonth.year, state.displayedMonth.month + 1, 1);
    state = state.copyWith(displayedMonth: nextMonth);
  }

  String _format(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
