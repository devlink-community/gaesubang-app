// lib/group/domain/repository/group_repository.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/attendance.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';
import 'package:devlink_mobile_app/group/domain/model/user_streak.dart';

abstract interface class GroupRepository {
  Future<Result<List<Group>>> getGroupList();
  Future<Result<Group>> getGroupDetail(String groupId);
  Future<Result<void>> joinGroup(String groupId);
  Future<Result<Group>> createGroup(Group group);
  Future<Result<void>> updateGroup(Group group);
  Future<Result<void>> leaveGroup(String groupId);
  Future<Result<List<Group>>> searchGroups(String query);

  /// 멤버 타이머 시작
  Future<Result<void>> startMemberTimer(String groupId);

  /// 멤버 타이머 정지 (완료)
  Future<Result<void>> stopMemberTimer(String groupId);

  /// 멤버 타이머 일시정지/재개
  Future<Result<void>> pauseMemberTimer(String groupId);

  /// 그룹 멤버 목록과 해당 타이머 상태 조회 (한 번만 조회)
  Future<Result<List<GroupMember>>> getGroupMembers(String groupId);

  /// 🔧 새로운 실시간 그룹 멤버 타이머 상태 스트림
  Stream<Result<List<GroupMember>>> streamGroupMemberTimerStatus(
    String groupId,
  );

  /// 특정 그룹의 특정 월 출석 기록 조회
  Future<Result<List<Attendance>>> getAttendancesByMonth(
    String groupId,
    int year,
    int month,
  );

  // ===== 새로 추가되는 메서드들 =====

  /// 특정 시간으로 타이머 활동 기록
  Future<Result<void>> recordTimerActivityWithTimestamp(
    String groupId,
    String activityType,
    DateTime timestamp,
  );

  /// 특정 시간으로 타이머 시작 기록
  Future<Result<void>> startMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  );

  /// 특정 시간으로 타이머 일시정지 기록
  Future<Result<void>> pauseMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  );

  /// 특정 시간으로 타이머 종료 기록
  Future<Result<void>> stopMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  );

  /// 현재 로그인한 사용자가 가입한 모든 그룹 중 최대 연속 출석일 조회
  Future<Result<UserStreak>> getUserMaxStreakDays();

  // 주간 공부 누적량
  Future<Result<int>> getWeeklyStudyTimeMinutes();
}
