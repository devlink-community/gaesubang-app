import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'attendance_notifier.dart';
import 'attendance_screen.dart';
import 'attendance_state.dart';
import 'attendance_action.dart';

class AttendanceScreenRoot extends ConsumerWidget {
  const AttendanceScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceNotifierProvider);
    final notifier = ref.watch(attendanceNotifierProvider.notifier);

    return AttendanceScreen(
      state: state,
      onAction: notifier.onAction,
    );
  }
}
