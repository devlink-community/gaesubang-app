import 'package:flutter/material.dart';

class WeekdayLabel extends StatelessWidget {
  final String label;
  const WeekdayLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFFCFCFCF),
        ),
      ),
    );
  }
}