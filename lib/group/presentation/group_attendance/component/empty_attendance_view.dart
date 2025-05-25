import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class EmptyAttendanceView extends StatelessWidget {
  const EmptyAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColorStyles.gray40.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy,
              size: 32,
              color: AppColorStyles.gray100,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '이 날짜에는 출석한 멤버가 없습니다',
            style: AppTextStyles.subtitle1Bold.copyWith(
              color: AppColorStyles.gray100,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '그룹 타이머를 사용해서 함께 공부해 보세요!',
            style: AppTextStyles.body2Regular.copyWith(
              color: AppColorStyles.gray80,
            ),
          ),
        ],
      ),
    );
  }
}
