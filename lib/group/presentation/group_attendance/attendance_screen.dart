import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/presentation/group_attendance/component/calendar_grid.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'attendance_action.dart';
import 'attendance_state.dart';

class AttendanceScreen extends StatelessWidget {
  final AttendanceState state;
  final void Function(AttendanceAction action) onAction;

  const AttendanceScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorStyles.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildCalendarContainer(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 세련된 SliverAppBar
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColorStyles.white,
      foregroundColor: AppColorStyles.textPrimary,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          '그룹 출석부',
          style: AppTextStyles.heading3Bold.copyWith(
            color: AppColorStyles.textPrimary,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColorStyles.primary100.withValues(alpha: 0.1),
                AppColorStyles.white,
              ],
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildMonthNavigation(),
        ),
      ),
    );
  }

  // 월 네비게이션
  Widget _buildMonthNavigation() {
    final displayedMonth = state.displayedMonth;
    final monthFormat = DateFormat('yyyy년 M월');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColorStyles.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColorStyles.blackOverlay(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavigationButton(
            icon: Icons.chevron_left,
            onPressed: () {
              final previousMonth = DateTime(
                displayedMonth.year,
                displayedMonth.month - 1,
              );
              onAction(AttendanceAction.changeMonth(previousMonth));
            },
          ),
          Text(
            monthFormat.format(displayedMonth),
            style: AppTextStyles.subtitle1Bold,
          ),
          _buildNavigationButton(
            icon: Icons.chevron_right,
            onPressed: () {
              final nextMonth = DateTime(
                displayedMonth.year,
                displayedMonth.month + 1,
              );
              onAction(AttendanceAction.changeMonth(nextMonth));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColorStyles.primary100.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: AppColorStyles.primary100,
            size: 20,
          ),
        ),
      ),
    );
  }

  // 캘린더 컨테이너
  Widget _buildCalendarContainer() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorStyles.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColorStyles.blackOverlay(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildWeekdayLabels(),
          const SizedBox(height: 16),
          _buildCalendarBody(),
        ],
      ),
    );
  }

  // 세련된 요일 라벨
  Widget _buildWeekdayLabels() {
    final weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    final weekdayColors = [
      AppColorStyles.error, // 일요일
      AppColorStyles.textPrimary, // 월요일
      AppColorStyles.textPrimary, // 화요일
      AppColorStyles.textPrimary, // 수요일
      AppColorStyles.textPrimary, // 목요일
      AppColorStyles.textPrimary, // 금요일
      AppColorStyles.primary100, // 토요일
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          weekdays.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            final color = weekdayColors[index];

            return Container(
              width: 40,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: AppTextStyles.captionRegular.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
    );
  }

  // 캘린더 본문
  Widget _buildCalendarBody() {
    switch (state.attendanceList) {
      case AsyncLoading():
        return Container(
          height: 300,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColorStyles.primary100.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: CircularProgressIndicator(
                  color: AppColorStyles.primary100,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '출석 데이터를 불러오는 중...',
                style: AppTextStyles.body1Regular.copyWith(
                  color: AppColorStyles.gray100,
                ),
              ),
            ],
          ),
        );

      case AsyncError(:final error):
        return Container(
          height: 300,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColorStyles.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 32,
                  color: AppColorStyles.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '출석 데이터를 불러올 수 없습니다',
                style: AppTextStyles.subtitle1Bold.copyWith(
                  color: AppColorStyles.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: AppTextStyles.body2Regular.copyWith(
                  color: AppColorStyles.gray100,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed:
                    () => onAction(const AttendanceAction.loadAttendanceData()),
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorStyles.primary100,
                  foregroundColor: AppColorStyles.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );

      case AsyncData():
        return _buildCalendarGrid();

      default:
        return Container(
          height: 300,
          alignment: Alignment.center,
          child: CircularProgressIndicator(
            color: AppColorStyles.primary100,
          ),
        );
    }
  }

  // 향상된 캘린더 그리드
  Widget _buildCalendarGrid() {
    final colorMap = _getAttendanceColorMap();

    return CalendarGrid(
      year: state.displayedMonth.year,
      month: state.displayedMonth.month,
      selectedDate: state.selectedDate,
      attendanceStatus: colorMap,
      onDateSelected: (date) {
        // 날짜 선택과 버텀 시트 표시를 동시에 요청
        onAction(AttendanceAction.selectDate(date));
        onAction(AttendanceAction.showDateAttendanceBottomSheet(date));
      },
    );
  }

  // 날짜별 출석 상태 색상 맵 생성
  Map<String, Color> _getAttendanceColorMap() {
    final colorMap = <String, Color>{};
    final attendances = state.attendanceList.valueOrNull ?? [];

    // 날짜별로 그룹화하여 해당 날짜의 총 활동량 계산
    final dateGrouped = <String, List<dynamic>>{};
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
        (sum, attendance) => sum + (attendance.timeInMinutes as int),
      );

      // 참여 멤버 수
      final memberCount = dayAttendances.map((a) => a.memberId).toSet().length;

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
}
