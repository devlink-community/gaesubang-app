import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/group/domain/model/attendance.dart';
import 'package:devlink_mobile_app/group/domain/usecase/attendance/get_attendance_by_month_use_case.dart';
import 'package:devlink_mobile_app/group/module/group_di.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
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
      attendanceColorMap: const <String, Color>{},
      isLocaleInitialized: false,
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
      case NavigateToUserProfile():
        // 노티파이어에서는 아무것도 하지 않음
        // 네비게이션은 Root에서 처리
        break;
    }
  }

  Future<void> _handleInitializeLocale() async {
    try {
      await initializeDateFormatting('ko_KR', null);
      AppLogger.info('로케일 초기화 성공', tag: 'AttendanceNotifier');

      state = state.copyWith(isLocaleInitialized: true);
    } catch (e) {
      AppLogger.warning(
        '로케일 초기화 실패, 기본값으로 진행',
        tag: 'AttendanceNotifier',
        error: e,
      );

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

    // 색상 맵 계산
    final colorMap = _calculateAttendanceColorMap(
      asyncResult.valueOrNull ?? [],
    );

    // 상태 업데이트 (출석 데이터와 색상 맵 동시에)
    state = state.copyWith(
      attendanceList: asyncResult,
      attendanceColorMap: colorMap,
    );
  }

  // 날짜별 출석 상태 색상 맵 계산
  Map<String, Color> _calculateAttendanceColorMap(
    List<Attendance> attendances,
  ) {
    final colorMap = <String, Color>{};

    // 날짜별로 그룹화하여 해당 날짜의 총 활동량 계산
    final dateGrouped = <String, List<Attendance>>{};
    for (final attendance in attendances) {
      final dateKey = DateFormat('yyyy-MM-dd').format(attendance.date);
      dateGrouped.putIfAbsent(dateKey, () => []);
      dateGrouped[dateKey]!.add(attendance);
    }

    // 각 날짜별로 색상 결정
    for (final entry in dateGrouped.entries) {
      final dateKey = entry.key;
      final dayAttendances = entry.value;

      // 해당 날짜의 총 학습 시간
      final totalMinutes = dayAttendances.fold<int>(
        0,
        (sum, attendance) => sum + attendance.timeInMinutes,
      );

      // 참여 멤버 수
      final memberCount = dayAttendances.map((a) => a.userId).toSet().length;

      // 멤버 수와 총 시간을 고려한 색상 결정
      if (memberCount >= 3 && totalMinutes >= 240) {
        colorMap[dateKey] = AppColorStyles.primary100; // 매우 활발
      } else if (memberCount >= 2 && totalMinutes >= 120) {
        colorMap[dateKey] = AppColorStyles.primary80; // 활발
      } else if (memberCount >= 1 && totalMinutes >= 30) {
        colorMap[dateKey] = AppColorStyles.primary60; // 보통
      } else {
        colorMap[dateKey] = AppColorStyles.gray40.withValues(alpha: 0.5); // 낮음
      }
    }

    return colorMap;
  }

  // 선택된 날짜의 출석 데이터 가져오기
  List<Attendance> getSelectedDateAttendances() {
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(state.selectedDate);
    final attendances = state.attendanceList.valueOrNull ?? <Attendance>[];

    return attendances.where((attendance) {
      final dateKey = DateFormat('yyyy-MM-dd').format(attendance.date);
      return dateKey == selectedDateStr;
    }).toList();
  }

  // 멤버별로 그룹화된 출석 데이터 가져오기
  Map<String, List<Attendance>> getGroupedAttendancesByMember() {
    final attendances = getSelectedDateAttendances();
    final groupedByMember = <String, List<Attendance>>{};

    for (final attendance in attendances) {
      final userId = attendance.userId;
      groupedByMember.putIfAbsent(userId, () => []);
      groupedByMember[userId]!.add(attendance);
    }

    return groupedByMember;
  }

  // 멤버별 총 학습 시간 계산 및 정렬된 데이터 가져오기
  List<MapEntry<String, List<Attendance>>> getSortedMemberAttendances() {
    final groupedByMember = getGroupedAttendancesByMember();

    final sortedEntries =
        groupedByMember.entries.toList()..sort((a, b) {
          final totalA = a.value.fold<int>(
            0,
            (sum, attendance) => sum + attendance.timeInMinutes,
          );
          final totalB = b.value.fold<int>(
            0,
            (sum, attendance) => sum + attendance.timeInMinutes,
          );
          return totalB.compareTo(totalA);
        });

    return sortedEntries;
  }

  // 총 학습 시간 계산
  int getTotalMinutes() {
    final attendances = getSelectedDateAttendances();
    return attendances.fold<int>(
      0,
      (sum, attendance) => sum + attendance.timeInMinutes,
    );
  }

  // 평균 학습 시간 계산
  int getAverageMinutes() {
    final groupedByMember = getGroupedAttendancesByMember();
    final totalMinutes = getTotalMinutes();
    final memberCount = groupedByMember.length;

    return memberCount > 0 ? totalMinutes ~/ memberCount : 0;
  }

  // 안전한 한국어 날짜 포맷팅
  String formatDateSafely(DateTime date, {String pattern = 'M월 d일 (E)'}) {
    if (!state.isLocaleInitialized) {
      // 로케일이 초기화되지 않은 경우 기본 포맷 사용
      return DateFormat('M월 d일').format(date);
    }

    try {
      return DateFormat(pattern, 'ko_KR').format(date);
    } catch (e) {
      AppLogger.warning(
        '한국어 날짜 포맷팅 실패, 기본 포맷 사용',
        tag: 'AttendanceNotifier',
        error: e,
      );
      // 한국어 포맷팅에 실패하면 기본 포맷 사용
      return DateFormat('M월 d일').format(date);
    }
  }
}
