// lib/auth/domain/service/summary_calculator.dart
import 'package:devlink_mobile_app/auth/domain/model/summary.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';

/// Summary 모델에서 통계 계산을 위한 유틸리티 클래스
class SummaryCalculator {
  const SummaryCalculator._(); // 인스턴스화 방지

  /// 요일별 활동 시간을 주문대로 반환 (월화수목금토일)
  static Map<String, int> getSortedWeeklyActivity(Summary summary) {
    // 한글 요일 순서로 정렬된 빈 맵 생성
    final Map<String, int> sortedMap = {
      '월': 0,
      '화': 0,
      '수': 0,
      '목': 0,
      '금': 0,
      '토': 0,
      '일': 0,
    };

    // 최근 7일 활동 데이터 변환
    if (summary.last7DaysActivityMap.isNotEmpty) {
      // 날짜 포맷에서 요일로 변환하여 처리
      summary.last7DaysActivityMap.forEach((dateStr, seconds) {
        try {
          final date = DateTime.parse(dateStr);
          final weekday = TimeFormatter.getKoreanWeekday(date.weekday);
          // 초를 분으로 변환
          final minutes = seconds ~/ 60;
          sortedMap[weekday] = minutes;
        } catch (e) {
          AppLogger.warning('날짜 파싱 오류: $dateStr', error: e);
        }
      });
    }

    return sortedMap;
  }

  /// 총 집중 시간 계산 (분 단위)
  static int getTotalMinutes(Summary summary) {
    return summary.allTimeTotalSeconds ~/ 60;
  }

  /// 이번 주 총 집중 시간 계산 (분 단위)
  static int getWeeklyTotalMinutes(Summary summary) {
    int total = 0;
    summary.last7DaysActivityMap.forEach((_, seconds) {
      total += seconds;
    });
    return total ~/ 60;
  }

  /// 오늘 집중 시간 계산 (분 단위)
  static int getTodayMinutes(Summary summary) {
    final today = TimeFormatter.nowInSeoul().toIso8601String().split('T')[0];
    final seconds = summary.last7DaysActivityMap[today] ?? 0;
    return seconds ~/ 60;
  }

  /// 사용자 활동 레벨 계산 (0-4 사이의 값)
  static int getActivityLevel(Summary summary) {
    final weeklyMinutes = getWeeklyTotalMinutes(summary);

    if (weeklyMinutes <= 0) return 0;
    if (weeklyMinutes < 60) return 1; // 1시간 미만
    if (weeklyMinutes < 180) return 2; // 3시간 미만
    if (weeklyMinutes < 420) return 3; // 7시간 미만
    return 4; // 7시간 이상
  }
}
