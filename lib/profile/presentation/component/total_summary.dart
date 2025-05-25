// lib/profile/presentation/component/total_summary.dart
import 'package:devlink_mobile_app/auth/domain/model/summary.dart';
import 'package:devlink_mobile_app/auth/domain/service/summary_calculator.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class TotalSummary extends StatelessWidget {
  final Summary summary;

  const TotalSummary({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    // 총 집중 시간 (분)
    final totalMinutes = SummaryCalculator.getTotalMinutes(summary);

    // 시간·분으로 변환 (예: 125분 → 2시간 5분)
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final display = hours > 0 ? '${hours}시간 ${minutes}분' : '${minutes}분';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time, size: 24, color: AppColorStyles.primary80),
          const SizedBox(width: 8),
          Text(
            '총 집중 시간: $display',
            style: AppTextStyles.button2Regular.copyWith(color: Colors.black),
          ),
        ],
      ),
    );
  }
}
