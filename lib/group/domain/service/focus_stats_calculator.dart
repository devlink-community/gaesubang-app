// lib/group/domain/service/focus_stats_calculator.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/auth/data/dto/timer_activity_dto.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:devlink_mobile_app/group/domain/model/attendance.dart';
import 'package:devlink_mobile_app/group/domain/model/timer_activity_type.dart';
import 'package:devlink_mobile_app/profile/domain/model/focus_time_stats.dart';
import 'package:intl/intl.dart';

/// 타이머 활동 로그를 기반으로 집중 통계를 계산하는 서비스 클래스
/// 주로 출석부, 사용자 프로필 등의 히스토리 기반 통계에 사용
class FocusStatsCalculator {
  const FocusStatsCalculator._();

  /// 타이머 활동 로그를 기반으로 집중 통계 계산
  static FocusTimeStats calculateFromActivities(
    List<TimerActivityDto> activities,
  ) {
    // 총 집중 시간 계산
    int totalMinutes = 0;

    // 요일별 집중 시간 계산
    final Map<String, int> weeklyMinutes = {
      '월': 0,
      '화': 0,
      '수': 0,
      '목': 0,
      '금': 0,
      '토': 0,
      '일': 0,
    };

    // 활동 시간순으로 정렬
    final sortedActivities = List<TimerActivityDto>.from(activities);
    sortedActivities.sort((a, b) {
      final aTime = a.timestamp;
      final bTime = b.timestamp;
      if (aTime == null || bTime == null) return 0;
      return aTime.compareTo(bTime);
    });

    // 시작 시간을 저장할 변수
    DateTime? startTime;

    // 모든 활동을 순차적으로 처리
    for (final activity in sortedActivities) {
      final type = activity.type;
      final timestamp = activity.timestamp;
      if (timestamp == null) continue;

      // 타이머 활동 유형에 따라 처리
      if (type == null) continue;
      final activityType = TimerActivityType.fromString(type);

      switch (activityType) {
        case TimerActivityType.start:
          // 새 타이머 세션 시작
          startTime = timestamp;

        case TimerActivityType.pause:
          // 현재 실행 중인 타이머가 있는 경우에만 처리
          if (startTime != null) {
            // 시작부터 일시정지까지 시간 계산
            final sessionMinutes = timestamp.difference(startTime).inMinutes;

            if (sessionMinutes > 0) {
              totalMinutes += sessionMinutes;

              // 요일별 시간 추가 (시작 날짜 기준)
              final weekday = TimeFormatter.getKoreanWeekday(startTime.weekday);
              weeklyMinutes[weekday] =
                  (weeklyMinutes[weekday] ?? 0) + sessionMinutes;
            }

            // 시작 시간 초기화 (일시정지 후에는 새로운 start가 와야 함)
            startTime = null;
          }

        case TimerActivityType.resume:
          // resume은 새로운 세션 시작으로 처리
          startTime = timestamp;

        case TimerActivityType.end:
          // 타이머가 실행 중인 경우에만 처리
          if (startTime != null) {
            // 시작부터 종료까지 시간 계산
            final sessionMinutes = timestamp.difference(startTime).inMinutes;

            if (sessionMinutes > 0) {
              totalMinutes += sessionMinutes;

              // 요일별 시간 추가 (시작 날짜 기준)
              final weekday = TimeFormatter.getKoreanWeekday(startTime.weekday);
              weeklyMinutes[weekday] =
                  (weeklyMinutes[weekday] ?? 0) + sessionMinutes;
            }

            // 시작 시간 초기화
            startTime = null;
          }
      }
    }

    return FocusTimeStats(
      totalMinutes: totalMinutes,
      weeklyMinutes: weeklyMinutes,
    );
  }

  /// 특정 기간의 집중 시간 계산
  static int calculateFocusMinutesInPeriod(
    List<TimerActivityDto> activities,
    DateTime startDate,
    DateTime endDate,
  ) {
    int totalMinutes = 0;

    // 활동 시간순으로 정렬
    final sortedActivities = List<TimerActivityDto>.from(activities);
    sortedActivities.sort((a, b) {
      final aTime = a.timestamp;
      final bTime = b.timestamp;
      if (aTime == null || bTime == null) return 0;
      return aTime.compareTo(bTime);
    });

    // 시작 시간을 저장할 변수
    DateTime? startTime;

    // 지정된 기간 내에 있는 활동만 필터링
    final periodActivities =
        sortedActivities.where((activity) {
          final timestamp = activity.timestamp;
          return timestamp != null &&
              timestamp.isAfter(startDate) &&
              timestamp.isBefore(endDate);
        }).toList();

    // 모든 활동을 순차적으로 처리
    for (final activity in periodActivities) {
      final type = activity.type;
      final timestamp = activity.timestamp;
      if (timestamp == null) continue;

      // 타이머 활동 유형에 따라 처리
      if (type == null) continue;
      final activityType = TimerActivityType.fromString(type);

      switch (activityType) {
        case TimerActivityType.start:
          // 새 타이머 세션 시작
          startTime = timestamp;

        case TimerActivityType.pause:
          // 현재 실행 중인 타이머가 있는 경우에만 처리
          if (startTime != null) {
            // 시작부터 일시정지까지 시간 계산
            final sessionMinutes = timestamp.difference(startTime).inMinutes;

            if (sessionMinutes > 0) {
              totalMinutes += sessionMinutes;
            }

            // 시작 시간 초기화 (일시정지 후에는 새로운 start가 와야 함)
            startTime = null;
          }

        case TimerActivityType.resume:
          // resume은 새로운 세션 시작으로 처리
          startTime = timestamp;

        case TimerActivityType.end:
          // 타이머가 실행 중인 경우에만 처리
          if (startTime != null) {
            // 시작부터 종료까지 시간 계산
            final sessionMinutes = timestamp.difference(startTime).inMinutes;

            if (sessionMinutes > 0) {
              totalMinutes += sessionMinutes;
            }

            // 시작 시간 초기화
            startTime = null;
          }
      }
    }

    return totalMinutes;
  }

  /// 오늘의 집중 시간 계산
  static int calculateTodayFocusMinutes(List<TimerActivityDto> activities) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return calculateFocusMinutesInPeriod(activities, startOfDay, endOfDay);
  }

  /// 이번 주 집중 시간 계산
  static int calculateWeeklyFocusMinutes(List<TimerActivityDto> activities) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final endOfWeek = startOfWeekDay.add(const Duration(days: 7));

    return calculateFocusMinutesInPeriod(activities, startOfWeekDay, endOfWeek);
  }

  /// 타이머 활동들로부터 출석 기록 계산
  static List<Attendance> calculateAttendancesFromActivities(
    String groupId,
    List<Map<String, dynamic>> activities,
  ) {
    // 멤버별, 날짜별로 활동 그룹화
    final Map<String, Map<String, List<Map<String, dynamic>>>>
    memberDateActivities = {};

    for (final activity in activities) {
      final userId = activity['userId'] as String?;
      final timestamp = activity['timestamp'];
      if (userId == null || timestamp == null) continue;

      final date = _parseTimestamp(timestamp);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);

      memberDateActivities[userId] ??= {};
      memberDateActivities[userId]![dateKey] ??= [];
      memberDateActivities[userId]![dateKey]!.add(activity);
    }

    // 각 멤버의 일별 총 활동 시간 계산
    final List<Attendance> attendances = [];

    memberDateActivities.forEach((userId, dateActivities) {
      dateActivities.forEach((dateKey, dayActivities) {
        // 시간순 정렬
        dayActivities.sort((a, b) {
          final timeA = _parseTimestamp(a['timestamp']);
          final timeB = _parseTimestamp(b['timestamp']);
          return timeA.compareTo(timeB);
        });

        // 세션별 시간 계산
        int totalMinutes = 0;
        DateTime? sessionStartTime;
        DateTime? lastPauseTime;

        for (final activity in dayActivities) {
          final typeString = activity['type'] as String;
          final type = TimerActivityType.fromString(typeString);
          final timestamp = _parseTimestamp(activity['timestamp']);

          switch (type) {
            case TimerActivityType.start:
              sessionStartTime = timestamp;
              lastPauseTime = null;
              break;

            case TimerActivityType.resume:
              // resume은 이전 pause 시점부터 계속
              if (lastPauseTime != null) {
                // pause-resume 간격은 계산하지 않음
                sessionStartTime = timestamp;
              }
              break;

            case TimerActivityType.pause:
              if (sessionStartTime != null) {
                // start/resume부터 pause까지의 시간 계산
                final duration = timestamp.difference(sessionStartTime);
                totalMinutes += duration.inMinutes;
                lastPauseTime = timestamp;
                sessionStartTime = null;
              }
              break;

            case TimerActivityType.end:
              if (sessionStartTime != null) {
                // start/resume부터 end까지의 시간 계산
                final duration = timestamp.difference(sessionStartTime);
                totalMinutes += duration.inMinutes;
              } else if (lastPauseTime != null) {
                // pause 상태에서 end된 경우 (자동 종료 등)
                // 이미 pause까지의 시간은 계산되었으므로 추가 계산 없음
              }
              sessionStartTime = null;
              lastPauseTime = null;
              break;
          }
        }

        // 마지막 활동이 start/resume인 경우 (세션이 진행 중)
        if (sessionStartTime != null) {
          final now = DateTime.now();
          final date = DateFormat('yyyy-MM-dd').parse(dateKey);

          // 오늘이면 현재 시간까지, 과거면 그날 23:59:59까지
          final endTime =
              TimeFormatter.isSameDay(date, now)
                  ? now
                  : DateTime(date.year, date.month, date.day, 23, 59, 59);

          final duration = endTime.difference(sessionStartTime);
          totalMinutes += duration.inMinutes;
        }

        if (totalMinutes > 0) {
          final userName = dayActivities.first['userName'] as String? ?? '';
          final profileUrl = dayActivities.first['profileUrl'] as String?;

          attendances.add(
            Attendance(
              groupId: groupId,
              userId: userId,
              userName: userName,
              profileUrl: profileUrl,
              date: DateFormat('yyyy-MM-dd').parse(dateKey),
              timeInMinutes: totalMinutes,
            ),
          );
        }
      });
    });

    return attendances;
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        return timestamp;
      }
      throw ArgumentError('Invalid timestamp type: ${timestamp.runtimeType}');
    } catch (e) {
      AppLogger.error(
        'Timestamp 파싱 실패',
        tag: 'FocusStats',
        error: e,
      );
      rethrow;
    }
  }
}
