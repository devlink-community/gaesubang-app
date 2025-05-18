import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'attendance_action.dart';
import 'attendance_notifier.dart';
import 'attendance_screen.dart';

class AttendanceScreenRoot extends ConsumerStatefulWidget {
  final String groupId;

  const AttendanceScreenRoot({super.key, required this.groupId});

  @override
  ConsumerState<AttendanceScreenRoot> createState() =>
      _AttendanceScreenRootState();
}

class _AttendanceScreenRootState extends ConsumerState<AttendanceScreenRoot> {
  @override
  void initState() {
    super.initState();
    // 한 번만 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(attendanceNotifierProvider.notifier)
          .onAction(AttendanceAction.setGroupId(widget.groupId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceNotifierProvider);
    final notifier = ref.watch(attendanceNotifierProvider.notifier);

    return AttendanceScreen(state: state, onAction: notifier.onAction);
  }
}
