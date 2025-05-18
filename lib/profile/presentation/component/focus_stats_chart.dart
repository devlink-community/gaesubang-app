import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/styles/app_color_styles.dart';
import '../../domain/model/focus_time_stats.dart';

class FocusStatsChart extends StatefulWidget {
  final FocusTimeStats stats;
  final bool animate;
  final Duration animationDuration;

  const FocusStatsChart({
    Key? key,
    required this.stats,
    this.animate = false,
    this.animationDuration = const Duration(milliseconds: 800),
  }) : super(key: key);

  @override
  State<FocusStatsChart> createState() => _FocusStatsChartState();
}

class _FocusStatsChartState extends State<FocusStatsChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    if (widget.animate) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1) 원본 데이터 정렬
    final entries =
        widget.stats.weeklyMinutes.entries.toList()..sort(
          (a, b) => _weekdayIndex(a.key).compareTo(_weekdayIndex(b.key)),
        );

    // 2) 최대값 계산
    final maxVal = entries
        .map((e) => e.value.toDouble())
        .fold<double>(0, (prev, curr) => max(prev, curr));

    // 3) 색상 정의 - 살짝 더 깊은 파란색 계열로 수정
    final fillColor = const Color(0xFF4355F9);
    final bgColor = AppColorStyles.gray40.withValues(alpha: 0.2);

    // 4) 한글 요일 배열 (0→월, 1→화, …)
    const korDays = ['월', '화', '수', '목', '금', '토', '일'];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxVal,
              // 터치 툴팁 가독성 설정
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.black87,
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  tooltipRoundedRadius: 6,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final idx = group.x.toInt();
                    final kor = korDays[idx];
                    final minutes = rod.toY.toInt();
                    return BarTooltipItem(
                      '$kor\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: '$minutes분',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              // 축 레이블: 아래만 한글 요일 표시
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= korDays.length)
                        return const SizedBox();
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          korDays[idx],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Bar 그룹 생성 - 애니메이션 적용
              barGroups:
                  entries.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final minutes = entry.value.value.toDouble();
                    // 애니메이션 적용 - 높이에 애니메이션 값 곱함
                    final animatedHeight = minutes * _animation.value;

                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: animatedHeight,
                          width: 16,
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [
                              fillColor.withValues(alpha: 0.6),
                              fillColor,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxVal,
                            color: bgColor,
                          ),
                        ),
                      ],
                      showingTooltipIndicators:
                          widget.animate && _animation.value < 1.0 ? [] : null,
                    );
                  }).toList(),
            ),
          ),
        );
      },
    );
  }

  int _weekdayIndex(String day) {
    const order = ['월', '화', '수', '목', '금', '토', '일'];
    return order.indexOf(day);
  }
}
