// lib/auth/domain/usecase/calculate_user_focus_stats_use_case.dart
import 'package:devlink_mobile_app/auth/domain/model/user_focus_stats.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/attendance.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';

class CalculateUserFocusStatsUseCase {
  final AuthRepository _authRepository;
  final GroupRepository _groupRepository;

  CalculateUserFocusStatsUseCase({
    required AuthRepository authRepository,
    required GroupRepository groupRepository,
  }) : _authRepository = authRepository,
       _groupRepository = groupRepository;

  /// 사용자가 참여한 모든 그룹의 출석 데이터를 합산해서 통계 계산
  Future<Result<UserFocusStats>> execute(String userId) async {
    try {
      print('🔍 CalculateUserFocusStatsUseCase: 사용자 통계 계산 시작');
      print('🔍 userId: $userId');

      // 1. 사용자 정보 조회 (참여 그룹 목록 포함)
      final userResult = await _authRepository.getUserProfile(userId);
      if (userResult case Error(:final failure)) {
        print('❌ 사용자 정보 조회 실패: $failure');
        return Error(failure);
      }

      final user = (userResult as Success).data;
      final joinedGroupIds =
          user.joinedGroups
              .map((group) => group.groupId)
              .where((id) => id != null)
              .cast<String>()
              .toList();

      print('✅ 사용자 참여 그룹: ${joinedGroupIds.length}개');

      if (joinedGroupIds.isEmpty) {
        // 참여한 그룹이 없으면 빈 통계 반환
        print('📊 참여한 그룹이 없어서 빈 통계 반환');
        return Success(UserFocusStats.empty());
      }

      // 2. 모든 그룹의 출석 데이터 수집 (최근 3개월)
      final allAttendances = await _fetchAllUserAttendances(
        userId,
        joinedGroupIds,
      );

      print('📊 총 출석 데이터: ${allAttendances.length}개');

      // 3. 통계 계산
      final stats = _calculateStatsFromAttendances(allAttendances);

      print('✅ 사용자 통계 계산 완료');
      print('📊 총 집중시간: ${stats.totalFocusMinutes}분');
      print('📅 이번 주: ${stats.weeklyFocusMinutes}분');
      print('🔥 연속 학습일: ${stats.streakDays}일');

      return Success(stats);
    } catch (e, stackTrace) {
      print('❌ CalculateUserFocusStatsUseCase 실행 중 오류: $e');
      print('Stack trace: $stackTrace');
      return Error(
        Failure(
          FailureType.unknown,
          '사용자 통계 계산 중 오류가 발생했습니다: $e',
          cause: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// 모든 그룹에서 사용자의 출석 데이터 수집
  Future<List<Attendance>> _fetchAllUserAttendances(
    String userId,
    List<String> groupIds,
  ) async {
    final allAttendances = <Attendance>[];
    final now = DateTime.now();

    // 각 그룹의 최근 3개월 데이터 수집
    for (final groupId in groupIds) {
      for (int i = 0; i < 3; i++) {
        final targetDate = DateTime(now.year, now.month - i, 1);
        final attendances = await _fetchGroupAttendances(
          groupId,
          targetDate.year,
          targetDate.month,
        );

        // 해당 사용자의 출석 데이터만 필터링
        final userAttendances =
            attendances
                .where((attendance) => attendance.memberId == userId)
                .toList();

        allAttendances.addAll(userAttendances);
      }
    }

    // 날짜순 정렬 (최신순)
    allAttendances.sort((a, b) => b.date.compareTo(a.date));

    return allAttendances;
  }

  /// 특정 그룹의 특정 월 출석 데이터 안전하게 조회
  Future<List<Attendance>> _fetchGroupAttendances(
    String groupId,
    int year,
    int month,
  ) async {
    try {
      final result = await _groupRepository.getAttendancesByMonth(
        groupId,
        year,
        month,
      );

      if (result case Success(:final data)) {
        return data;
      } else {
        print('⚠️ 그룹 $groupId의 $year-$month 출석 데이터 조회 실패');
        return <Attendance>[];
      }
    } catch (e) {
      print('⚠️ 그룹 $groupId의 $year-$month 출석 데이터 조회 중 오류: $e');
      return <Attendance>[];
    }
  }

  /// 출석 데이터로부터 UserFocusStats 계산
  UserFocusStats _calculateStatsFromAttendances(List<Attendance> attendances) {
    // 총 집중시간 계산
    final totalMinutes = attendances.fold<int>(
      0,
      (sum, attendance) => sum + attendance.timeInMinutes,
    );

    // 이번 주 집중시간 계산 (최근 7일)
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1)); // 이번 주 월요일
    final weekStartDate = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    final weeklyMinutes = attendances
        .where(
          (attendance) =>
              attendance.date.isAfter(weekStartDate) ||
              attendance.date.isAtSameMomentAs(weekStartDate),
        )
        .fold<int>(0, (sum, attendance) => sum + attendance.timeInMinutes);

    // 연속 학습일 계산
    final streakDays = _calculateStreakDays(attendances);

    return UserFocusStats(
      totalFocusMinutes: totalMinutes,
      weeklyFocusMinutes: weeklyMinutes,
      streakDays: streakDays,
      lastUpdated: DateTime.now(),
    );
  }

  /// 연속 학습일 계산
  int _calculateStreakDays(
    List<Attendance> attendances, {
    int minMinutes = 25,
  }) {
    if (attendances.isEmpty) return 0;

    // 유효한 학습일만 필터링 (최소 25분 이상)
    final validStudyDays =
        attendances
            .where((attendance) => attendance.timeInMinutes >= minMinutes)
            .map((attendance) => attendance.date)
            .toSet() // 중복 제거 (같은 날 여러 그룹 활동)
            .toList()
          ..sort((a, b) => b.compareTo(a)); // 최신순

    if (validStudyDays.isEmpty) return 0;

    // 오늘부터 역순으로 연속일 계산
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    int streakDays = 0;
    DateTime checkDate = todayDateOnly;

    for (final studyDate in validStudyDays) {
      final studyDateOnly = DateTime(
        studyDate.year,
        studyDate.month,
        studyDate.day,
      );

      if (studyDateOnly.isAtSameMomentAs(checkDate)) {
        // 연속된 날짜 발견
        streakDays++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (studyDateOnly.isBefore(checkDate)) {
        // 날짜가 건너뛰어짐 - 연속 끊어짐
        break;
      }
      // studyDate가 checkDate보다 미래면 건너뜀
    }

    return streakDays;
  }
}
