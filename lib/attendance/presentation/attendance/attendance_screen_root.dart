import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/model/group.dart'; // 수정된 임포트
import 'attendance_action.dart';
import 'attendance_notifier.dart';
import 'attendance_screen.dart';

class AttendanceScreenRoot extends ConsumerWidget {
  final Group group;

  const AttendanceScreenRoot({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceNotifierProvider);
    final notifier = ref.watch(attendanceNotifierProvider.notifier);

    // 초기 그룹 선택 처리
    // Root가 첫 번째로 빌드될 때 group 정보 설정
    ref.listenManual(attendanceNotifierProvider, (_, __) {
      Future.microtask(() {
        notifier.onAction(AttendanceAction.selectGroup(group));
      });
    }, fireImmediately: true);

    return AttendanceScreen(
      state: state,
      onAction: notifier.onAction,
    );
  }
}