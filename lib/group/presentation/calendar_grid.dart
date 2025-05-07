import 'package:flutter/material.dart';

class CalendarGrid extends StatelessWidget {
  final int year;
  final int month;
  final DateTime selectedDate;
  final void Function(DateTime) onDateSelected;
  final Map<DateTime, Color> attendanceStatus;
  final bool Function(DateTime, DateTime) isSameDay;

  const CalendarGrid({
    super.key,
    required this.year,
    required this.month,
    required this.selectedDate,
    required this.onDateSelected,
    required this.attendanceStatus,
    required this.isSameDay,
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
                final isSelected = isSameDay(date, selectedDate);
                final attendanceColor = attendanceStatus.entries.firstWhere(
                      (entry) => isSameDay(entry.key, date),
                  orElse: () => MapEntry(date, Colors.transparent),
                ).value;

                return _DateCell(
                  date: date,
                  isSelected: isSelected,
                  attendanceColor: attendanceColor,
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

class _DateCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final Color attendanceColor;
  final void Function(DateTime) onTap;

  const _DateCell({
    required this.date,
    required this.isSelected,
    required this.attendanceColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(date),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: attendanceColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          date.day.toString(),
          style: TextStyle(
            fontSize: isSelected ? 24 : 20,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: const Color(0xFF262424),
          ),
        ),
      ),
    );
  }
}
