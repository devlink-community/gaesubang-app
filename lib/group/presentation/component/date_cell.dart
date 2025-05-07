import 'package:flutter/material.dart';

class DateCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final Color? attendanceColor;
  final void Function(DateTime) onTap;

  const DateCell({
    super.key,
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
          '${date.day}',
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