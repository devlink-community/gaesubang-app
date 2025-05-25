import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class AttendanceSummaryCard extends StatelessWidget {
  final int totalMinutes;
  final int memberCount;
  final int avgMinutes;

  const AttendanceSummaryCard({
    super.key,
    required this.totalMinutes,
    required this.memberCount,
    required this.avgMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColorStyles.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColorStyles.primary100.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppColorStyles.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '일일 요약',
                style: AppTextStyles.subtitle1Bold.copyWith(
                  color: AppColorStyles.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '총 학습시간',
                      style: AppTextStyles.captionRegular.copyWith(
                        color: AppColorStyles.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatMinutes(totalMinutes),
                      style: AppTextStyles.subtitle1Bold.copyWith(
                        color: AppColorStyles.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColorStyles.white.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '참여 멤버',
                      style: AppTextStyles.captionRegular.copyWith(
                        color: AppColorStyles.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$memberCount명',
                      style: AppTextStyles.subtitle1Bold.copyWith(
                        color: AppColorStyles.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColorStyles.white.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '평균 시간',
                      style: AppTextStyles.captionRegular.copyWith(
                        color: AppColorStyles.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatMinutes(avgMinutes),
                      style: AppTextStyles.subtitle1Bold.copyWith(
                        color: AppColorStyles.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 활동량 시각화
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: AppColorStyles.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                  width:
                      (totalMinutes > 0)
                          ? (totalMinutes /
                              (totalMinutes + 120) *
                              MediaQuery.of(context).size.width *
                              0.8)
                          : 0,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColorStyles.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0) {
      return '$hours시간 ${mins > 0 ? "$mins분" : ""}';
    } else {
      return '$mins분';
    }
  }
}
