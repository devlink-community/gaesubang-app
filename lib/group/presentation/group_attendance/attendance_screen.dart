import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/presentation/group_attendance/component/calendar_grid.dart';
import 'package:devlink_mobile_app/group/presentation/group_attendance/component/weekday_label.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
      appBar: AppBar(
        title: Text('출석부', style: AppTextStyles.heading3Bold),
        elevation: 0,
      ),
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
    switch (state.attendanceList) {
      case AsyncLoading():
        return const SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        );

      case AsyncError(:final error):
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '출석 데이터를 불러올 수 없습니다: ${error.toString()}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed:
                    () => onAction(const AttendanceAction.loadAttendanceData()),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        );

      case AsyncData():
        return _buildCalendarGrid();
      default:
        return const SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        );
    }
  }

  // Calendar Grid 위젯 생성
  Widget _buildCalendarGrid() {
    // AttendanceNotifier로부터 색상 맵을 직접 제공받는 대신 여기서 생성
    final colorMap = _getAttendanceColorMap();

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
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    switch (state.attendanceList) {
      case AsyncLoading():
        return const SizedBox(
          height: 50,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );

      case AsyncError():
        return const Text('데이터를 불러올 수 없습니다');

      case AsyncData(:final value):
        return _buildAttendanceListForDate(value, selectedDateStr);
      default:
        return const SizedBox(
          height: 50,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
    }
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

    // 멤버별로 그룹화하여 표시
    final groupedByMember = <String, List<dynamic>>{};
    for (final attendance in attendancesForDate) {
      final memberId = attendance.memberId;
      groupedByMember.putIfAbsent(memberId, () => []);
      groupedByMember[memberId]!.add(attendance);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          groupedByMember.entries.map((entry) {
            final memberId = entry.key;
            final memberAttendances = entry.value;

            // 해당 멤버의 총 출석 시간 계산
            final totalMinutes = memberAttendances
                .map((a) => a.timeInMinutes as int)
                .reduce((a, b) => a + b);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getColorByTime(totalMinutes),
                  child: Text(
                    // 멤버 이름의 첫 글자 표시 (없으면 '?')
                    memberAttendances.first.memberName?.substring(0, 1) ?? '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  memberAttendances.first.memberName ?? '멤버 $memberId',
                ),
                subtitle: Text('출석 시간: ${_formatMinutes(totalMinutes)}'),
                trailing: Icon(
                  _getIconByTime(totalMinutes),
                  color: _getColorByTime(totalMinutes),
                ),
              ),
            );
          }).toList(),
    );
  }

  // 출석 시간에 따른 색상 반환
  Color _getColorByTime(int minutes) {
    if (minutes >= 240) {
      return const Color(0xFF5D5FEF); // 4시간 이상 - primary100
    } else if (minutes >= 120) {
      return const Color(0xFF7879F1); // 2시간 이상 - primary80
    } else if (minutes >= 30) {
      return const Color(0xFFA5A6F6); // 30분 이상 - primary60
    } else {
      return Colors.grey; // 30분 미만
    }
  }

  // 출석 시간에 따른 아이콘 반환
  IconData _getIconByTime(int minutes) {
    if (minutes >= 240) {
      return Icons.star; // 4시간 이상 - 별
    } else if (minutes >= 120) {
      return Icons.thumb_up; // 2시간 이상 - 좋아요
    } else if (minutes >= 30) {
      return Icons.check_circle; // 30분 이상 - 체크
    } else {
      return Icons.access_time; // 30분 미만 - 시계
    }
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
  Map<String, Color> _getAttendanceColorMap() {
    final colorMap = <String, Color>{};

    final attendances = state.attendanceList.valueOrNull ?? [];
    for (final attendance in attendances) {
      final dateKey = DateFormat('yyyy-MM-dd').format(attendance.date);

      if (attendance.timeInMinutes >= 240) {
        // 4시간 이상
        colorMap[dateKey] = const Color(
          0xFF5D5FEF,
        ); // #5D5FEF - AppColorStyles.primary100
      } else if (attendance.timeInMinutes >= 120) {
        // 2시간 이상
        colorMap[dateKey] = const Color(
          0xFF7879F1,
        ); // #7879F1 - AppColorStyles.primary80
      } else if (attendance.timeInMinutes >= 30) {
        // 30분 이상
        colorMap[dateKey] = const Color(
          0xFFA5A6F6,
        ); // #A5A6F6 - AppColorStyles.primary60
      } else {
        colorMap[dateKey] = Colors.grey.withValues(alpha: 0.3);
      }
    }

    return colorMap;
  }
}
