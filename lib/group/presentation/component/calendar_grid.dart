import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'date_cell.dart';

class CalendarGrid extends StatelessWidget {
  final int year;
  final int month;
  final DateTime selectedDate;
  final void Function(DateTime) onDateSelected;
  final Map<String, Color> attendanceStatus;

  const CalendarGrid({
    super.key,
    required this.year,
    required this.month,
    required this.selectedDate,
    required this.onDateSelected,
    required this.attendanceStatus,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(year, month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final weeksInMonth = ((daysInMonth + firstWeekday) / 7).ceil();

    return Column(
      children: List.generate(weeksInMonth, (weekIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 30.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (dayIndex) {
              final day = weekIndex * 7 + dayIndex + 1 - firstWeekday;
              if (day > 0 && day <= daysInMonth) {
                final date = DateTime(year, month, day);
                final dateKey = DateFormat('yyyy-MM-dd').format(date);
                final isSelected = dateKey == DateFormat('yyyy-MM-dd').format(selectedDate);
                final color = attendanceStatus[dateKey];
                return DateCell(
                  date: date,
                  isSelected: isSelected,
                  attendanceColor: color,
                  onTap: onDateSelected,
                );
              } else {
                return const SizedBox(width: 40, height: 40);
              }
            }),
          ),
        );
      }),
    );
  }
}