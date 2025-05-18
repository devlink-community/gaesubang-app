import 'package:devlink_mobile_app/group/module/attendance_di.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../group/domain/usecase/get_attendance_by_month_use_case.dart';
import '../../../group/domain/usecase/mock_get_group_detail_use_case.dart';
import 'attendance_action.dart';
import 'attendance_state.dart';

part 'attendance_notifier.g.dart';

@riverpod
class AttendanceNotifier extends _$AttendanceNotifier {
  late final GetAttendancesByMonthUseCase _getAttendancesByMonthUseCase;
  late final MockGetGroupDetailUseCase _mockGetGroupDetailUseCase;

  @override
  AttendanceState build() {
    _getAttendancesByMonthUseCase = ref.watch(
      getAttendancesByMonthUseCaseProvider,
    );
    _mockGetGroupDetailUseCase = ref.watch(mockGetGroupDetailUseCaseProvider);

    final now = DateTime.now();
    return AttendanceState(
      groupDetail: const AsyncValue.loading(),
      displayedMonth: DateTime(now.year, now.month),
      selectedDate: now,
      attendanceList: const AsyncValue.loading(),
    );
  }

  Future<void> onAction(AttendanceAction action) async {
    switch (action) {
      case SetGroupId(:final groupId):
        await _handleSetGroupId(groupId);
      case SelectDate(:final date):
        _handleSelectDate(date);
      case ChangeMonth(:final month):
        await _handleChangeMonth(month);
      case LoadAttendanceData():
        await _loadAttendanceData();
    }
  }

  Future<void> _handleSetGroupId(String groupId) async {
    try {
      // 그룹 정보 로딩 상태 설정
      state = state.copyWith(
        groupDetail: const AsyncValue.loading(),
        attendanceList: const AsyncValue.loading(),
      );

      // Mock Group Detail UseCase를 통해 그룹 정보 조회
      final groupResult = await _mockGetGroupDetailUseCase.execute(groupId);

      // UseCase 결과를 바로 상태에 할당
      state = state.copyWith(groupDetail: groupResult);

      // 그룹 정보 로드가 성공한 경우에만 출석 데이터 로드
      if (groupResult case AsyncData()) {
        await _loadAttendanceData();
      }
    } catch (e, stackTrace) {
      // 최상위 예외 처리 - 모든 예외를 상태로 변환
      print('🚨 Uncaught exception in _handleSetGroupId: $e');
      state = state.copyWith(
        groupDetail: AsyncError(e, stackTrace),
        attendanceList: AsyncError(e, stackTrace),
      );
    }
  }

  void _handleSelectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  Future<void> _handleChangeMonth(DateTime month) async {
    if (month.year == state.displayedMonth.year &&
        month.month == state.displayedMonth.month)
      return;

    state = state.copyWith(
      displayedMonth: month,
      attendanceList: const AsyncValue.loading(),
    );

    await _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    final group = state.groupDetail.valueOrNull;
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

      if (attendance.time >= 240) {
        // 4시간 이상
        colorMap[dateKey] = const Color(0xFF5D5FEF); // primary100
      } else if (attendance.time >= 120) {
        // 2시간 이상
        colorMap[dateKey] = const Color(0xFF7879F1); // primary80
      } else if (attendance.time >= 30) {
        // 30분 이상
        colorMap[dateKey] = const Color(0xFFA5A6F6); // primary60
      } else {
        colorMap[dateKey] = Colors.grey.withValues(alpha: 0.3);
      }
    }

    return colorMap;
  }
}
