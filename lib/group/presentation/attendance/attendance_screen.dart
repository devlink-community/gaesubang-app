import 'package:flutter/material.dart';
import '../component/calendar_grid.dart';
import '../component/weekday_label.dart';

class AttendanceScreen extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime displayedMonth;
  final Map<String, Color> attendanceStatus;
  final void Function(DateTime) onDateSelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const AttendanceScreen({
    super.key,
    required this.selectedDate,
    required this.displayedMonth,
    required this.attendanceStatus,
    required this.onDateSelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '출석부',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  WeekdayLabel(label: 'SUN'),
                  WeekdayLabel(label: 'MON'),
                  WeekdayLabel(label: 'TUE'),
                  WeekdayLabel(label: 'WED'),
                  WeekdayLabel(label: 'THU'),
                  WeekdayLabel(label: 'FRI'),
                  WeekdayLabel(label: 'SAT'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            CalendarGrid(
              year: displayedMonth.year,
              month: displayedMonth.month,
              selectedDate: selectedDate,
              onDateSelected: onDateSelected,
              attendanceStatus: attendanceStatus,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left, color: Color(0xFFA5A6F6)),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right, color: Color(0xFFA5A6F6)),
              ),
            ],
          ),
          Text(
            "${displayedMonth.year}.${displayedMonth.month.toString().padLeft(2, '0')}",
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF262424),
            ),
          ),
        ],
      ),
    );
  }
}
