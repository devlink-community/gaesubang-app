import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../calendar_grid.dart';
import 'attendance_action.dart';
import 'attendance_state.dart'; // ← 이거는 기존 캘린더 위젯 분리했을 경우

class AttendanceScreen extends StatelessWidget {
  final AttendanceState state;
  final void Function(AttendanceAction action) onAction;

  const AttendanceScreen({super.key, required this.state, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final displayedMonth = DateTime.now(); // 필요한 경우 상태에 추가 가능
    final attendanceStatus = <DateTime, Color>{};

    state.attendances.whenOrNull(data: (list) {
      for (final item in list) {
        final color = switch (item.percentage) {
          >= 80 => const Color(0xFF5D5FEF),
          >= 50 => const Color(0xFF7879F1),
          >= 20 => const Color(0xFFA5A6F6),
          _ => Colors.transparent,
        };
        final fakeDate = DateTime(displayedMonth.year, displayedMonth.month, list.indexOf(item) + 1);
        attendanceStatus[fakeDate] = color;
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('출석부')),
      body: CalendarGrid(
        year: displayedMonth.year,
        month: displayedMonth.month,
        selectedDate: DateTime.now(),
        attendanceStatus: attendanceStatus,
        onDateSelected: (date) => onAction(AttendanceAction.selectMember(date.toIso8601String())),
        isSameDay: (a, b) => a.year == b.year && a.month == b.month && a.day == b.day,
      ),
    );
  }
}
