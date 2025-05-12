import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'attendance_action.dart';
import 'attendance_state.dart';
import '../component/calendar_grid.dart';
import '../component/weekday_label.dart';

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
      appBar: AppBar(
        title: Text('출석부',
        style: AppTextStyles.heading3Bold,),
        backgroundColor: Colors.white,
        foregroundColor: Colors.transparent, // 추가 설정
        elevation: 0,

      ),
      backgroundColor: Colors.white,

      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCalendarHeader(),
            const SizedBox(height: 20),
            _buildWeekdayLabels(),
            const SizedBox(height: 10),
            _buildCalendarBody(),
            const SizedBox(height: 20),
            _buildSelectedDateInfo(),
          ],
        ),
      ),
    );
  }

  // 캘린더 헤더 (년-월 표시 및 이전/다음 버튼)
  Widget _buildCalendarHeader() {
    final displayedMonth = state.displayedMonth;
    final monthFormat = DateFormat('yyyy년 M월');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
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
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
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

  // 18 semiboard //E3E3E3
  // 요일 라벨 (일~토)
  Widget _buildWeekdayLabels() {
    final weekdays = ['SUN', 'MON', 'TUE', 'WEN', 'THU', 'FRI', 'SAT'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: weekdays.map((day) => WeekdayLabel(label: day)).toList(),
      ),
    );
  }

  // 캘린더 본문 (날짜 그리드)
  Widget _buildCalendarBody() {
    return state.attendanceList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  '데이터를 불러올 수 없습니다: ${error.toString()}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed:
                      () =>
                          onAction(const AttendanceAction.loadAttendanceData()),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
      data: (data) => _buildCalendarGrid(),
    );
  }

  // Calendar Grid 위젯 생성
  Widget _buildCalendarGrid() {
    // Notifier에서 색상 맵을 생성하는 메서드 사용
    // 실제로는 도메인 로직이 Notifier에 있어야 하지만, 간단한 표시를 위해 이렇게 구현
    final colorMap =
        (state.selectedGroup != null)
            ? _getAttendanceColorMap()
            : <String, Color>{};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CalendarGrid(
        year: state.displayedMonth.year,
        month: state.displayedMonth.month,
        selectedDate: state.selectedDate,
        attendanceStatus: colorMap,
        onDateSelected: (date) => onAction(AttendanceAction.selectDate(date)),
      ),
    );
  }

  // 선택된 날짜에 대한 정보 표시
  Widget _buildSelectedDateInfo() {
    final selectedDate = state.selectedDate;
    final dateStr = DateFormat('yyyy년 M월 d일').format(selectedDate);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.white,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$dateStr 출석 정보',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildSelectedDateAttendanceInfo(selectedDate),
            ],
          ),
        ),
      ),
    );
  }

  // 선택된 날짜의 출석 정보 상세 표시
  Widget _buildSelectedDateAttendanceInfo(DateTime selectedDate) {
    // 선택된 날짜의 출석 정보 필터링
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    return state.attendanceList.when(
      loading:
          () => const SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      error: (error, stackTrace) => const Text('데이터를 불러올 수 없습니다'),
      data:
          (attendances) =>
              _buildAttendanceListForDate(attendances, selectedDateStr),
    );
  }

  // 특정 날짜의 출석 목록 표시
  Widget _buildAttendanceListForDate(
    List<dynamic> attendances,
    String selectedDateStr,
  ) {
    final attendancesForDate =
        attendances
            .where(
              (a) => DateFormat('yyyy-MM-dd').format(a.date) == selectedDateStr,
            )
            .toList();

    if (attendancesForDate.isEmpty) {
      return const Text('이 날짜에 출석 정보가 없습니다');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          attendancesForDate.map((attendance) {
            // 출석 회원을 찾아서 표시 (이름 등)
            // 간단히 memberId를 표시
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('멤버 ID: ${attendance.memberId}'),
              subtitle: Text('출석 시간: ${_formatMinutes(attendance.time)}'),
            );
          }).toList(),
    );
  }

  // 분 단위 시간을 시간:분 형식으로 변환
  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0) {
      return '$hours시간 ${mins > 0 ? "$mins분" : ""}';
    } else {
      return '$mins분';
    }
  }

  // 날짜별 출석 상태 색상 맵 생성
  // 실제로는 이런 도메인 로직이 Notifier에 있어야 하지만,
  // 샘플 코드에서는 UI에서 직접 계산하도록 구현
  Map<String, Color> _getAttendanceColorMap() {
    final colorMap = <String, Color>{};

    final attendances = state.attendanceList.valueOrNull ?? [];
    for (final attendance in attendances) {
      final dateKey = DateFormat('yyyy-MM-dd').format(attendance.date);

      if (attendance.time >= 240) {
        // 4시간 이상
        colorMap[dateKey] = const Color(
          0xFF5D5FEF,
        ); // #5D5FEF - AppColorStyles.primary100
      } else if (attendance.time >= 120) {
        // 2시간 이상
        colorMap[dateKey] = const Color(
          0xFF7879F1,
        ); // #7879F1 - AppColorStyles.primary80
      } else if (attendance.time >= 30) {
        // 30분 이상
        colorMap[dateKey] = const Color(
          0xFFA5A6F6,
        ); // #A5A6F6 - AppColorStyles.primary60
      } else {
        colorMap[dateKey] = Colors.grey.withOpacity(0.3);
      }
    }

    return colorMap;
  }
}
