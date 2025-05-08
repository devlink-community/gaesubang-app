import 'package:devlink_mobile_app/group/module/attendance_di.dart';
import 'package:flutter/material.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/result/result.dart';
import '../../domain/usecase/get_attendance_by_group_use_case.dart';
import 'attendance_action.dart';
import 'attendance_state.dart';

part 'attendance_notifier.g.dart';

@riverpod
class AttendanceNotifier extends _$AttendanceNotifier {
  late final GetAttendanceByGroupUseCase _useCase;

  @override
  AttendanceState build() {
    final today = DateTime.now();
    final initialState = AttendanceState(
      groupId: 'group1',
      selectedDate: today,
      displayedMonth: DateTime(today.year, today.month, 1),
    );

    Future.microtask(() {
      _useCase = ref.watch(getAttendanceByDateUseCaseProvider);
      loadAttendance(initialState.groupId);
    });

    return initialState;
  }

  void onAction(AttendanceAction action) {
    action.process(
      load: (action) => loadAttendance(state.groupId),
      selectGroupId: (action) {
        state = state.copyWith(groupId: action.groupId);
        loadAttendance(action.groupId);
      },
      selectDate: (action) => onDateSelected(action.date),
      previousMonth: (_) => onPreviousMonth(),
      nextMonth: (_) => onNextMonth(),
    );
  }

  // 날짜 선택 UI
  void onDateSelected(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  // 이전 달 이동
  void onPreviousMonth() {
    final prev = DateTime(
      state.displayedMonth.year,
      state.displayedMonth.month - 1,
      1,
    );
    state = state.copyWith(displayedMonth: prev);
  }

  // 다음 달 이동
  void onNextMonth() {
    final next = DateTime(
      state.displayedMonth.year,
      state.displayedMonth.month + 1,
      1,
    );
    state = state.copyWith(displayedMonth: next);
  }

  // 출석 데이터 불러오기
  Future<void> loadAttendance(String groupId) async {
    state = state.copyWith(loading: const AsyncLoading());

    final result = await _useCase.execute(groupId: groupId);

    if (result is Success) {
      final attendances = (result as Success).data;
      print('Loaded attendances: ${attendances.length}');
      final newStatus = <String, Color>{};

      for (final a in attendances) {
        final key =
            '${a.date.year}-${a.date.month.toString().padLeft(2, '0')}-${a.date.day.toString().padLeft(2, '0')}';
        final color = switch (a.time) {
          >= 240 => const Color(0xFF5D5FEF), // 80%
          >= 120 => const Color(0xFF7879F1), // 50%
          >= 60 => const Color(0xFFA5A6F6), // 20%
          _ => Colors.transparent, // 0%
        };
        newStatus[key] = color;
      }
      print('Converted status map: $newStatus');

      state = state.copyWith(
        attendanceStatus: newStatus,
        loading: const AsyncData(null),
      );
    } else if (result is Error) {
      final failure = (result as Error).failure;
      final stackTrace = failure.stackTrace ?? StackTrace.current;
      state = state.copyWith(loading: AsyncError(failure, stackTrace));
    }
  }
}
