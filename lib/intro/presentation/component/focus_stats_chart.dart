import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/model/focus_time_stats.dart';

class FocusStatsChart extends StatelessWidget {
  final FocusTimeStats stats;
  const FocusStatsChart({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1) 한글 요일 순서대로 정렬된 리스트
    final days =
        stats.weeklyMinutes.entries.toList()..sort(
          (a, b) => _weekdayIndex(a.key).compareTo(_weekdayIndex(b.key)),
        );

    // 2) 최대값 계산 (배경 바 높이 기준)
    final maxVal = days
        .map((e) => e.value.toDouble())
        .fold<double>(0, (prev, curr) => max(prev, curr));

    // 3) 색상 정의
    final fillColor = Theme.of(context).primaryColor;
    final bgColor = fillColor.withOpacity(0.2);

    return SizedBox(
      height: 200, // 원하는 높이로 조정
      child: BarChart(
        BarChartData(
          maxY: maxVal,
          // 눈금, 테두리 모두 숨김
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          // 축 레이블 모두 숨기고, 아래 축에만 요일 표시
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= days.length) return const SizedBox();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      days[idx].key, // "월","화",...
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // 실제 바 그룹 생성
          barGroups:
              days.asMap().entries.map((entry) {
                final idx = entry.key;
                final minutes = entry.value.value.toDouble();
                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: minutes,
                      width: 16,
                      borderRadius: BorderRadius.circular(8),
                      color: fillColor,
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxVal,
                        color: bgColor,
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  int _weekdayIndex(String day) {
    const order = ['월', '화', '수', '목', '금', '토', '일'];
    return order.indexOf(day);
  }
}
