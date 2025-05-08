import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/model/group.dart';
import 'attendance_action.dart';
import 'attendance_notifier.dart';
import 'attendance_screen.dart';

class AttendanceScreenRoot extends ConsumerWidget {
  final Group group;

  const AttendanceScreenRoot({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceNotifierProvider);
    final notifier = ref.read(attendanceNotifierProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.onAction(AttendanceAction.selectGroup(group));
    });

    return AttendanceScreen(
      state: state,
      onAction: notifier.onAction,
    );
  }
}
