import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/result/result.dart';
import '../../domain/usecase/get_attendance_by_group_use_case.dart';
import '../../module/attendance_di.dart';
import 'attendance_action.dart';
import 'attendance_state.dart';

part 'attendance_notifier.g.dart';

@riverpod
class AttendanceNotifier extends _$AttendanceNotifier {
  late final GetAttendanceByDateUseCase _useCase;

  @override
  AttendanceState build() {
    final today = DateTime.now();
    final members = ref.watch(mockMembersProvider);
    final initialState = AttendanceState(
      selectedDate: today,
      displayedMonth: DateTime(today.year, today.month, 1),
      members: members,
    );

    Future.microtask(() {
      _useCase = ref.watch(getAttendanceByDateUseCaseProvider);
      loadAttendance();
    });

    return initialState;
  }

  void onAction(AttendanceAction action) {
    action.process(
      load: (action) => loadAttendance(),
      selectGroupId: (action) {

        loadAttendance();
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
  Future<void> loadAttendance() async {
    state = state.copyWith(loading: const AsyncLoading());

    // state.members에서 ID 목록 가져오기
    final memberIds = state.members.map((m) => m.id).toList();

    // memberIds가 비어있으면 기본 ID 목록 사용
    final idsToUse = memberIds.isEmpty
        ? ['user1', 'user2', 'user3', 'user4']
        : memberIds;

    final result = await _useCase.execute(
      memberIds: idsToUse,
      date: state.selectedDate,
    );

    print('✅ memberIds: $idsToUse');
    print('✅ selectedDate: ${DateFormat('yyyy-MM-dd').format(state.selectedDate)}');

    if (result is Success) {
      final attendances = (result as Success).data;
      print('Loaded attendances: ${attendances.length}');
      final newStatus = <String, Color>{};

      for (final a in attendances) {
        // DateFormat을 사용하여 날짜 키 생성 - 일관성을 위해
        final key = DateFormat('yyyy-MM-dd').format(a.date);

        final color = switch (a.time) {
          >= 240 => const Color(0xFF5D5FEF), // 80%
          >= 120 => const Color(0xFF7879F1), // 50%
          >= 60 => const Color(0xFFA5A6F6), // 20%
          _ => Colors.transparent, // 0%
        };
        newStatus[key] = color;
        print('생성된 키: $key, 색상: $color'); // 디버깅용 로그 추가
      }
      print('전체 상태 맵: $newStatus');

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