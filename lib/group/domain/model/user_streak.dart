import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_streak.freezed.dart';

@freezed
class UserStreak with _$UserStreak {
  const UserStreak({
    required this.maxStreakDays,
    this.bestGroupId,
    this.bestGroupName,
    required this.lastActiveDate,
  });

  /// 최대 연속 출석일
  final int maxStreakDays;

  /// 가장 높은 연속 출석일을 기록한 그룹 ID
  final String? bestGroupId;

  /// 가장 높은 연속 출석일을 기록한 그룹 이름
  final String? bestGroupName;

  /// 마지막 활동 날짜
  final DateTime lastActiveDate;

  /// 연속 출석 중인지 확인 (오늘 또는 어제 활동 여부)
  bool get isActiveStreak {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastActive = DateTime(
      lastActiveDate.year,
      lastActiveDate.month,
      lastActiveDate.day,
    );

    return lastActive == today || lastActive == yesterday;
  }

  /// 연속 출석일 표시 텍스트
  String get streakDisplayText {
    if (maxStreakDays == 0) {
      return '연속 출석 없음';
    } else if (isActiveStreak) {
      return '$maxStreakDays일 연속 출석 중';
    } else {
      return '최고 $maxStreakDays일 연속 출석';
    }
  }
}
