import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'attendance_notifier.dart';
import 'attendance_screen.dart';

class AttendanceScreenRoot extends ConsumerWidget {
  const AttendanceScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceNotifierProvider);
    final notifier = ref.watch(attendanceNotifierProvider.notifier);

    return AttendanceScreen(
      selectedDate: state.selectedDate,
      displayedMonth: state.displayedMonth,
      attendanceStatus: state.attendanceStatus,
      onDateSelected: notifier.onDateSelected,
      onPreviousMonth: notifier.onPreviousMonth,
      onNextMonth: notifier.onNextMonth,
    );
  }
}
