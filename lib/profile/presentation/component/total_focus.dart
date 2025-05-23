import 'package:flutter/material.dart';

import '../../../core/styles/app_color_styles.dart';
import '../../../core/styles/app_text_styles.dart';

class TotalTimeInfo extends StatelessWidget {
  /// 총 집중 시간을 분 단위로 전달합니다.
  final int totalMinutes;

  const TotalTimeInfo({Key? key, required this.totalMinutes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🚀 디버그 로그 추가
    debugPrint('🚀 TotalTimeInfo: 받은 totalMinutes = $totalMinutes');

    // 시간·분으로 변환 (예: 125분 → 2시간 5분)
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final display = hours > 0 ? '${hours}시간 ${minutes}분' : '${minutes}분';

    debugPrint('🚀 TotalTimeInfo: 표시될 텍스트 = $display');

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
