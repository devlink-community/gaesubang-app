import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/result/result.dart';
import '../../domain/usecase/get_attendance_by_member_use_case.dart';
import '../../module/attendance_di.dart';
import 'attendance_action.dart';
import 'attendance_state.dart';

part 'attendance_notifier.g.dart';

@riverpod
class AttendanceNotifier extends _$AttendanceNotifier {
  late final GetAttendanceByMemberUseCase _useCase;

  @override
  AttendanceState build() {
    _useCase = ref.watch(getAttendanceByMemberUseCaseProvider);

    final today = DateTime.now();

    Future.microtask(() => loadAttendance('user4'));

    return AttendanceState(
      selectedDate: today,
      displayedMonth: DateTime(today.year, today.month),
    );
  }

  // 액션 처리 메서드 추가 - AttendanceScreenRoot에서 사용
  void onAction(AttendanceAction action) {
    action.process(
      load: (action) => loadAttendance('current_member_id'), // 멤버 ID 적절히 설정 필요
      selectMember: (action) => loadAttendance(action.memberId),
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
    final prevMonth = DateTime(state.displayedMonth.year, state.displayedMonth.month - 1);
    state = state.copyWith(displayedMonth: prevMonth);
  }

  // 다음 달 이동
  void onNextMonth() {
    final nextMonth = DateTime(state.displayedMonth.year, state.displayedMonth.month + 1);
    state = state.copyWith(displayedMonth: nextMonth);
  }

  // 출석 데이터 불러오기
  Future<void> loadAttendance(String memberId) async {

    state = state.copyWith(loading: const AsyncLoading());

    final result = await _useCase.execute(memberId);

    if (result is Success) {
      final attendances = (result as Success).data;
      print('Loaded attendances: ${attendances.length}');
      final newStatus = <String, Color>{};

      for (final a in attendances) {
        final key = '${a.date.year}-${a.date.month.toString().padLeft(2, '0')}-${a.date.day.toString().padLeft(2, '0')}';
        final color = switch (a.time) {
          >= 240 => const Color(0xFF5D5FEF), // 80%
          >= 120 => const Color(0xFF7879F1), // 50%
          >= 60 => const Color(0xFFA5A6F6),  // 20%
          _ => Colors.transparent,           // 0%
        };
        newStatus[key] = color;
      }
      print('Converted status map: $newStatus');

      state = state.copyWith(attendanceStatus: newStatus, loading: const AsyncData(null));
    } else if (result is Error) {
      final failure = (result as Error).failure;
      final stackTrace = failure.stackTrace ?? StackTrace.current;
      state = state.copyWith(loading: AsyncError(failure, stackTrace));
    }
  }

}