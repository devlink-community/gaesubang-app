import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'attendance_notifier.dart';
import 'attendance_screen.dart';

class AttendanceScreenRoot extends ConsumerWidget {
  const AttendanceScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceNotifierProvider);
    final notifier = ref.read(attendanceNotifierProvider.notifier);

    return AttendanceScreen(
      state: state,
      onAction: notifier.onAction,
    );
  }
}
