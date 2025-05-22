import 'package:devlink_mobile_app/group/domain/usecase/get_attendance_by_month_use_case.dart';
import 'package:devlink_mobile_app/group/module/group_di.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'attendance_action.dart';
import 'attendance_state.dart';

part 'attendance_notifier.g.dart';

@riverpod
class AttendanceNotifier extends _$AttendanceNotifier {
  late final GetAttendancesByMonthUseCase _getAttendancesByMonthUseCase;
  String? _groupId;

  @override
  AttendanceState build() {
    _getAttendancesByMonthUseCase = ref.watch(
      getAttendancesByMonthUseCaseProvider,
    );

    final now = DateTime.now();
    return AttendanceState(
      displayedMonth: DateTime(now.year, now.month),
      selectedDate: now,
      attendanceList: const AsyncValue.loading(),
      isLocaleInitialized: false, // 🔧 초기값은 false
    );
  }

  Future<void> onAction(AttendanceAction action) async {
    switch (action) {
      case InitializeLocale():
        await _handleInitializeLocale();
      case SetGroupId(:final groupId):
        await _handleSetGroupId(groupId);
      case SelectDate(:final date):
        _handleSelectDate(date);
      case ChangeMonth(:final month):
        await _handleChangeMonth(month);
      case LoadAttendanceData():
        await _loadAttendanceData();
      case ShowDateAttendanceBottomSheet():
        // 이 액션은 Root에서 처리하므로 여기서는 아무것도 하지 않음
        break;
    }
  }

  // 🔧 새로 추가: 로케일 초기화 처리
  Future<void> _handleInitializeLocale() async {
    try {
      await initializeDateFormatting('ko_KR', null);
      print('✅ 로케일 초기화 성공');

      state = state.copyWith(isLocaleInitialized: true);
    } catch (e) {
      print('⚠️ 로케일 초기화 실패, 기본값으로 진행: $e');

      // 로케일 초기화에 실패해도 앱은 계속 동작하도록 함
      state = state.copyWith(isLocaleInitialized: true);
    }
  }

  Future<void> _handleSetGroupId(String groupId) async {
    _groupId = groupId;
    state = state.copyWith(attendanceList: const AsyncValue.loading());
    await _loadAttendanceData();
  }

  void _handleSelectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  Future<void> _handleChangeMonth(DateTime month) async {
    // 월이 변경된 경우에만 데이터를 새로 로드
    if (month.year == state.displayedMonth.year &&
        month.month == state.displayedMonth.month) {
      return;
    }

    state = state.copyWith(
      displayedMonth: month,
      attendanceList: const AsyncValue.loading(),
    );

    await _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    if (_groupId == null) return;

    // 단일 API 호출로 출석 데이터 가져오기
    final asyncResult = await _getAttendancesByMonthUseCase.execute(
      groupId: _groupId!,
      year: state.displayedMonth.year,
      month: state.displayedMonth.month,
    );

    state = state.copyWith(attendanceList: asyncResult);
  }

  // 날짜별 출석 상태 색상 맵 생성 (UI에서 사용)
  Map<String, Color> getAttendanceColorMap() {
    final colorMap = <String, Color>{};

    final attendances = state.attendanceList.valueOrNull ?? [];
    for (final attendance in attendances) {
      final dateKey = DateFormat('yyyy-MM-dd').format(attendance.date);

      if (attendance.timeInMinutes >= 240) {
        // 4시간 이상
        colorMap[dateKey] = const Color(0xFF5D5FEF); // primary100
      } else if (attendance.timeInMinutes >= 120) {
        // 2시간 이상
        colorMap[dateKey] = const Color(0xFF7879F1); // primary80
      } else if (attendance.timeInMinutes >= 30) {
        // 30분 이상
        colorMap[dateKey] = const Color(0xFFA5A6F6); // primary60
      } else {
        colorMap[dateKey] = Colors.grey.withValues(alpha: 0.3);
      }
    }

    return colorMap;
  }

  // 🔧 새로 추가: 안전한 한국어 날짜 포맷팅
  String formatDateSafely(DateTime date, {String pattern = 'M월 d일 (E)'}) {
    if (!state.isLocaleInitialized) {
      // 로케일이 초기화되지 않은 경우 기본 포맷 사용
      return DateFormat('M월 d일').format(date);
    }

    try {
      return DateFormat(pattern, 'ko_KR').format(date);
    } catch (e) {
      print('⚠️ 한국어 날짜 포맷팅 실패, 기본 포맷 사용: $e');
      // 한국어 포맷팅에 실패하면 기본 포맷 사용
      return DateFormat('M월 d일').format(date);
    }
  }
}
