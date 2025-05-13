import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/material.dart';

import '../../data/module/attendance_di.dart';
import '../../domain/model/attendance.dart';
import '../../domain/usecase/get_attendance_by_month_use_case.dart';
import 'attendance_action.dart';
import 'attendance_state.dart';

part 'attendance_notifier.g.dart';

@riverpod
class AttendanceNotifier extends _$AttendanceNotifier {
  late final GetAttendancesByMonthUseCase _getAttendancesByMonthUseCase;

  @override
  AttendanceState build() {
    _getAttendancesByMonthUseCase = ref.watch(getAttendancesByMonthUseCaseProvider);

    // 현재 날짜 기준 초기 상태 설정
    final now = DateTime.now();
    return AttendanceState(
      selectedGroup: null,
      displayedMonth: DateTime(now.year, now.month),
      selectedDate: now,
      attendanceList: const AsyncValue.loading(),
    );
  }

  Future<void> onAction(AttendanceAction action) async {
    switch (action) {
      case SelectGroup(:final group):
        await _handleSelectGroup(group);
      case SelectDate(:final date):
        _handleSelectDate(date);
      case ChangeMonth(:final month):
        await _handleChangeMonth(month);
      case LoadAttendanceData():
        await _loadAttendanceData();
    }
  }

  Future<void> _handleSelectGroup(dynamic group) async {
    if (group == state.selectedGroup) return;

    state = state.copyWith(
      selectedGroup: group,
      attendanceList: const AsyncValue.loading(),
    );

    await _loadAttendanceData();
  }

  void _handleSelectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  Future<void> _handleChangeMonth(DateTime month) async {
    if (month.year == state.displayedMonth.year &&
        month.month == state.displayedMonth.month) return;

    state = state.copyWith(
      displayedMonth: month,
      attendanceList: const AsyncValue.loading(),
    );

    await _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    final group = state.selectedGroup;
    if (group == null) return;

    final memberIds = group.members.map((e) => e.id).toList();

    if (memberIds.isEmpty) {
      state = state.copyWith(attendanceList: const AsyncData([]));
      return;
    }

    final asyncResult = await _getAttendancesByMonthUseCase.execute(
      memberIds: memberIds,
      groupId: group.id,
      displayedMonth: state.displayedMonth,
    );

    state = state.copyWith(attendanceList: asyncResult);
  }

  // 날짜별 출석 상태 색상 맵 생성 (UI에서 사용)
  Map<String, Color> getAttendanceColorMap() {
    final colorMap = <String, Color>{};

    final attendances = state.attendanceList.valueOrNull ?? [];
    for (final attendance in attendances) {
      final dateKey = DateFormat('yyyy-MM-dd').format(attendance.date);

      // 시간에 따른 색상 설정 (예: 시간이 길수록 진한 색상)
      // 여기서는 간단한 예시로 30분 기준점을 사용
      if (attendance.time >= 240) { // 4시간 이상
        colorMap[dateKey] = Colors.green;
      } else if (attendance.time >= 120) { // 2시간 이상
        colorMap[dateKey] = Colors.lightGreen;
      } else if (attendance.time >= 30) { // 30분 이상
        colorMap[dateKey] = Colors.lightGreen.withOpacity(0.5);
      } else {
        colorMap[dateKey] = Colors.grey.withOpacity(0.3);
      }
    }

    return colorMap;
  }
}