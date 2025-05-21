// lib/core/utils/focus_stats_calculator.dart
import 'package:devlink_mobile_app/auth/data/dto/timer_activity_dto.dart';
import 'package:devlink_mobile_app/group/domain/model/attendance.dart';
import 'package:devlink_mobile_app/profile/domain/model/focus_time_stats.dart';

class FocusStatsCalculator {
  const FocusStatsCalculator._();

  /// 타이머 활동 로그를 기반으로 집중 통계 계산
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

      switch (type) {
        case 'start':
          // 새 타이머 세션 시작
          startTime = timestamp;

        case 'pause':
          // 현재 실행 중인 타이머가 있는 경우에만 처리
          if (startTime != null) {
            // 시작부터 일시정지까지 시간 계산
            final sessionMinutes = timestamp.difference(startTime).inMinutes;

            if (sessionMinutes > 0) {
              totalMinutes += sessionMinutes;

              // 요일별 시간 추가 (시작 날짜 기준)
              final weekday = _getKoreanWeekday(startTime.weekday);
              weeklyMinutes[weekday] =
                  (weeklyMinutes[weekday] ?? 0) + sessionMinutes;
            }

            // 시작 시간 초기화 (일시정지 후에는 새로운 start가 와야 함)
            startTime = null;
          }

        case 'end':
          // 타이머가 실행 중인 경우에만 처리
          if (startTime != null) {
            // 시작부터 종료까지 시간 계산
            final sessionMinutes = timestamp.difference(startTime).inMinutes;

            if (sessionMinutes > 0) {
              totalMinutes += sessionMinutes;

              // 요일별 시간 추가 (시작 날짜 기준)
              final weekday = _getKoreanWeekday(startTime.weekday);
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

      switch (type) {
        case 'start':
          // 새 타이머 세션 시작
          startTime = timestamp;

        case 'pause':
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

        case 'end':
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

  /// 요일 숫자를 한글 요일로 변환
  static String _getKoreanWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '월';
    }
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

  /// 그룹 타이머 활동에서 출석 기록 계산
  static List<Attendance> calculateAttendancesFromActivities(
    String groupId,
    List<dynamic> activities,
  ) {
    // 날짜별, 멤버별 활동 시간을 집계할 맵
    final Map<String, Map<String, int>> memberDailyMinutes = {};

    // 멤버 정보를 저장할 맵 (memberId -> (name, profileUrl))
    final Map<String, (String, String?)> memberInfoMap = {};

    // 시작 시간을 저장할 임시 맵 (memberId -> 시작 시간)
    final Map<String, DateTime> memberStartTimes = {};

    // 활동 시간순 정렬
    activities.sort((a, b) {
      final aTime = a['timestamp'] as DateTime?;
      final bTime = b['timestamp'] as DateTime?;
      if (aTime == null || bTime == null) return 0;
      return aTime.compareTo(bTime);
    });

    // 모든 활동 로그를 순회하며 분석
    for (final activity in activities) {
      final memberId = activity['memberId'];
      final timestamp = activity['timestamp'] as DateTime?;
      final type = activity['type'] as String?;

      if (memberId == null || timestamp == null || type == null) continue;

      // 멤버 정보 저장 (이름, 프로필 이미지 URL)
      if (activity['memberName'] != null) {
        memberInfoMap[memberId] = (
          activity['memberName'],
          activity['profileUrl'],
        );
      }

      // 날짜(YYYY-MM-DD) 추출
      final dateKey =
          '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';

      if (type == 'start') {
        // 타이머 시작 - 시작 시간 저장
        memberStartTimes[memberId] = timestamp;
      } else if (type == 'pause' && memberStartTimes.containsKey(memberId)) {
        // 타이머 일시정지 - 시작 시간부터 일시정지까지의 시간 계산
        final startTime = memberStartTimes[memberId]!;
        final durationMinutes = timestamp.difference(startTime).inMinutes;

        // 시간이 0 이상인 경우에만 기록
        if (durationMinutes > 0) {
          // 멤버별 날짜별 맵 초기화
          memberDailyMinutes[memberId] ??= {};
          memberDailyMinutes[memberId]![dateKey] ??= 0;

          // 해당 날짜에 시간 추가
          memberDailyMinutes[memberId]![dateKey] =
              memberDailyMinutes[memberId]![dateKey]! + durationMinutes;
        }

        // 시작 시간 제거 (다음 start까지 기다림)
        memberStartTimes.remove(memberId);
      } else if (type == 'end' && memberStartTimes.containsKey(memberId)) {
        // 타이머 정지 - 시작 시간부터 종료까지의 시간 계산
        final startTime = memberStartTimes[memberId]!;
        final durationMinutes = timestamp.difference(startTime).inMinutes;

        // 시간이 0 이상인 경우에만 기록
        if (durationMinutes > 0) {
          // 멤버별 날짜별 맵 초기화
          memberDailyMinutes[memberId] ??= {};
          memberDailyMinutes[memberId]![dateKey] ??= 0;

          // 해당 날짜에 시간 추가
          memberDailyMinutes[memberId]![dateKey] =
              memberDailyMinutes[memberId]![dateKey]! + durationMinutes;
        }

        // 시작 시간 제거 (다음 계산을 위해)
        memberStartTimes.remove(memberId);
      }
    }

    // 집계된 시간 데이터를 Attendance 모델로 변환
    final List<Attendance> attendances = [];

    memberDailyMinutes.forEach((memberId, dailyMinutes) {
      final memberInfo = memberInfoMap[memberId] ?? ('Unknown', null);

      dailyMinutes.forEach((dateKey, minutes) {
        final dateParts = dateKey.split('-');
        if (dateParts.length == 3) {
          try {
            final date = DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
            );

            attendances.add(
              Attendance(
                groupId: groupId,
                memberId: memberId,
                memberName: memberInfo.$1,
                profileUrl: memberInfo.$2,
                date: date,
                timeInMinutes: minutes,
              ),
            );
          } catch (e) {
            // 날짜 파싱 오류 시 스킵
            print('날짜 파싱 오류: $dateKey - $e');
          }
        }
      });
    });

    // 날짜별로 정렬
    attendances.sort((a, b) => a.date.compareTo(b.date));

    return attendances;
  }
}
