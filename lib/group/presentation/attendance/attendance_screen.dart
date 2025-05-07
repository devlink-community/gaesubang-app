import 'package:flutter/material.dart';
import '../component/calendar_grid.dart';
import 'attendance_action.dart';
import 'attendance_state.dart';

class AttendanceScreen extends StatelessWidget {
  final AttendanceState state;
  final void Function(AttendanceAction) onAction;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => onAction(const AttendanceAction.previousMonth()),
                ),
                Text(
                  '${state.displayedMonth.year}년 ${state.displayedMonth.month}월',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => onAction(const AttendanceAction.nextMonth()),
                ),
              ],
            ),
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
}
