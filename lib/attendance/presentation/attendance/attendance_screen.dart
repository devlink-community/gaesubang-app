import 'package:flutter/material.dart';

import 'attendance_action.dart';
import 'attendance_state.dart';
import '../component/calendar_grid.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('출석부'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildHeader(state.displayedMonth),
            const SizedBox(height: 12),
            CalendarGrid(
              year: state.displayedMonth.year,
              month: state.displayedMonth.month,
              selectedDate: state.selectedDate,
              onDateSelected: (date) => onAction(AttendanceAction.selectDate(date)),
              attendanceStatus: state.attendanceStatus,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(DateTime displayedMonth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onAction(const AttendanceAction.previousMonth()),
        ),
        Text(
          '${displayedMonth.year}년 ${displayedMonth.month}월',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onAction(const AttendanceAction.nextMonth()),
        ),
      ],
    );
  }
}
