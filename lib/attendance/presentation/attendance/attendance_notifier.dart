import 'package:devlink_mobile_app/attendance/module/attendance_di.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/model/group.dart';
import '../../domain/usecase/get_attendance_by_month_use_case.dart';
import 'attendance_action.dart';
import 'attendance_state.dart';

part 'attendance_notifier.g.dart';

@riverpod
class AttendanceNotifier extends _$AttendanceNotifier {
  late final GetAttendancesByMonthUseCase _getAttendancesByMonthUseCase;
  Group? _group;

  @override
  AttendanceState build() {
    _getAttendancesByMonthUseCase = ref.watch(getAttendancesByMonthUseCaseProvider);

    final today = DateTime.now();
    return AttendanceState(
      selectedDate: today,
      displayedMonth: DateTime(today.year, today.month, 1),
    );
  }

  Future<void> onAction(AttendanceAction action) async {
    switch (action) {
      case SelectGroup(:final group):
        _group = group;
        await _loadAttendance(group);
        break;
      case SelectDate(:final date):
        state = state.copyWith(selectedDate: date);
        break;
      case PreviousMonth():
        final prevMonth = DateTime(state.displayedMonth.year, state.displayedMonth.month - 1, 1);
        state = state.copyWith(displayedMonth: prevMonth);
        if (_group case final group?) await _loadAttendance(group);
        break;
      case NextMonth():
        final nextMonth = DateTime(state.displayedMonth.year, state.displayedMonth.month + 1, 1);
        state = state.copyWith(displayedMonth: nextMonth);
        if (_group case final group?) await _loadAttendance(group);
        break;
      case LoadAttendance():
        if (_group case final group?) await _loadAttendance(group);
        break;
    }
  }

  Future<void> _loadAttendance(Group group) async {
    state = state.copyWith(loading: const AsyncLoading(), members: group.members);

    final memberIds = group.members.map((m) => m.id).toList();

    final result = await _getAttendancesByMonthUseCase.execute(
      memberIds: memberIds,
      groupId: group.id,
      displayedMonth: state.displayedMonth,
    );

    switch (result) {
      case AsyncData(:final value):
        final statusMap = <String, Color>{};

        for (final attendance in value) {
          final key = DateFormat('yyyy-MM-dd').format(attendance.date);
          final color = switch (attendance.time) {
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

      case AsyncError(:final error):
        state = state.copyWith(
          loading: AsyncError(error, StackTrace.current),
        );

      case AsyncLoading():
      // 이미 처리됨
        break;
    }
  }
}