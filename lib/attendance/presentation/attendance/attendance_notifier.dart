import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/result/result.dart';
import '../../domain/model/attendance.dart';
import '../../domain/model/group.dart';
import '../../domain/usecase/get_attendance_by_month_use_case.dart';
import '../../module/attendance_di.dart';
import 'attendance_action.dart';
import 'attendance_state.dart';

part 'attendance_notifier.g.dart';

@riverpod
class AttendanceNotifier extends _$AttendanceNotifier {
  Group? _group;

  @override
  AttendanceState build() {
    final today = DateTime.now();
    return AttendanceState(
      selectedDate: today,
      displayedMonth: DateTime(today.year, today.month, 1),
    );
  }

  void onAction(AttendanceAction action) {
    switch (action) {
      case SelectGroup(:final group):
        _group = group;
        _loadAttendance(group);
        break;
      case SelectDate(:final date):
        state = state.copyWith(selectedDate: date);
        break;
      case PreviousMonth():
        final prevMonth = DateTime(state.displayedMonth.year, state.displayedMonth.month - 1, 1);
        state = state.copyWith(displayedMonth: prevMonth);
        if (_group case final group?) _loadAttendance(group);
        break;
      case NextMonth():
        final nextMonth = DateTime(state.displayedMonth.year, state.displayedMonth.month + 1, 1);
        state = state.copyWith(displayedMonth: nextMonth);
        if (_group case final group?) _loadAttendance(group);
        break;
      case LoadAttendance():
        if (_group case final group?) _loadAttendance(group);
        break;
    }
  }

  Future<void> _loadAttendance(Group group) async {
    state = state.copyWith(loading: const AsyncLoading(), members: group.members);

    final memberIds = group.members.map((m) => m.id).toList();
    final useCase = ref.watch(getAttendancesByMonthUseCaseProvider);

    final result = await useCase.execute(
      memberIds: memberIds,
      displayedMonth: state.displayedMonth,
    );

    if (result case Success<List<Attendance>>(:final data)) {
      final statusMap = <String, Color>{};

      for (final a in data) {
        final key = DateFormat('yyyy-MM-dd').format(a.date);
        final color = switch (a.time) {
          >= 240 => const Color(0xFF5D5FEF),
          >= 120 => const Color(0xFF7879F1),
          >= 60 => const Color(0xFFA5A6F6),
          _ => Colors.transparent,
        };
        statusMap[key] = color;
      }

      state = state.copyWith(
        attendanceStatus: statusMap,
        loading: const AsyncData(null),
      );
    } else if (result case Error(:final failure)) {
      state = state.copyWith(
        loading: AsyncError(failure, failure.stackTrace ?? StackTrace.current),
      );
    }
  }
}
