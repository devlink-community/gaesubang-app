import 'package:devlink_mobile_app/group/domain/model/attendance.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'attendance_state.freezed.dart';

@freezed
class AttendanceState with _$AttendanceState {
  const AttendanceState({
    // 현재 표시 중인 월 (캘린더 상단에 표시되는 년-월)
    required this.displayedMonth,

    // 캘린더에서 선택된 날짜
    required this.selectedDate,

    // 출석 정보 목록 (AsyncValue로 로딩/에러/데이터 상태 관리)
    this.attendanceList = const AsyncValue.loading(),

    // 날짜별 출석 상태 색상 맵
    this.attendanceColorMap = const <String, Color>{},

    this.isLocaleInitialized = false,
  });

  @override
  final DateTime displayedMonth;
  @override
  final DateTime selectedDate;
  @override
  final AsyncValue<List<Attendance>> attendanceList;
  @override
  final Map<String, Color> attendanceColorMap;
  @override
  final bool isLocaleInitialized;
}
