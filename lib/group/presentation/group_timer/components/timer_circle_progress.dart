import 'dart:math';

import 'package:flutter/material.dart';

class TimerCircleProgress extends StatelessWidget {
  const TimerCircleProgress({
    super.key,
    required this.elapsedSeconds,
    required this.totalSeconds,
    this.radius = 120,
    this.strokeWidth = 15,
  });

  final int elapsedSeconds;
  final int totalSeconds;
  final double radius;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds > 0 ? elapsedSeconds / totalSeconds : 0.0;

    return CustomPaint(
      size: Size(radius * 2, radius * 2),
      painter: _TimerCirclePainter(
        progress: progress,
        strokeWidth: strokeWidth,
        backgroundColor: Colors.grey[300]!,
        progressColor: Colors.blue,
      ),
      child: Center(
        child: Text(
          _formatTime(elapsedSeconds),
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class _TimerCirclePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  _TimerCirclePainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - strokeWidth / 2;

    // 배경 원 그리기
    final backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 진행 원호 그리기
    final progressPaint =
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // 12시 방향에서 시작
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_TimerCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
