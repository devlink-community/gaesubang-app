// lib/group/domain/repository/group_repository.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/attendance.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';
import 'package:devlink_mobile_app/group/domain/model/timer_activity_type.dart';

abstract interface class GroupRepository {
  Future<Result<List<Group>>> getGroupList();
  Future<Result<Group>> getGroupDetail(String groupId);
  Future<Result<void>> joinGroup(String groupId);
  Future<Result<Group>> createGroup(Group group);
  Future<Result<void>> updateGroup(Group group);
  Future<Result<void>> leaveGroup(String groupId);
  Future<Result<List<Group>>> searchGroups(String query);
  Future<Result<List<GroupMember>>> getGroupMembers(String groupId);

  /// 실시간 그룹 멤버 타이머 상태 스트림
  Stream<Result<List<GroupMember>>> streamGroupMemberTimerStatus(
    String groupId,
  );

  /// 특정 그룹의 특정 월 출석 기록 조회
  Future<Result<List<Attendance>>> getAttendancesByMonth(
    String groupId,
    int year,
    int month,
  );

  // ===== 타이머 액션 관련 메서드 =====

  /// 타이머 활동 기록 - 모든 타이머 액션의 기본 메서드
  ///
  /// [groupId] 그룹 ID
  /// [activityType] 활동 타입 (TimerActivityType enum 사용)
  /// [timestamp] 타임스탬프 (null인 경우 현재 시간 사용)
  ///
  /// 모든 타이머 관련 액션은 내부적으로 이 메서드를 사용합니다.
  Future<Result<void>> recordTimerActivity(
    String groupId,
    TimerActivityType activityType, {
    DateTime? timestamp,
  });

  /// 타이머 활동 기록 - 타임스탬프 지정 버전
  ///
  /// [groupId] 그룹 ID
  /// [activityType] 활동 타입 (TimerActivityType enum 사용)
  /// [timestamp] 타임스탬프
  Future<Result<void>> recordTimerActivityWithTimestamp(
    String groupId,
    TimerActivityType activityType,
    DateTime timestamp,
  );

  /// 멤버 타이머 시작
  /// 내부적으로 recordTimerActivity를 호출하여 구현
  Future<Result<void>> startMemberTimer(String groupId);

  /// 멤버 타이머 일시정지
  /// 내부적으로 recordTimerActivity를 호출하여 구현
  Future<Result<void>> pauseMemberTimer(String groupId);

  /// 멤버 타이머 재개
  /// 내부적으로 recordTimerActivity를 호출하여 구현
  Future<Result<void>> resumeMemberTimer(String groupId);

  /// 멤버 타이머 종료 (완료)
  /// 내부적으로 recordTimerActivity를 호출하여 구현
  Future<Result<void>> stopMemberTimer(String groupId);

  /// 특정 시간으로 타이머 시작 기록
  /// 내부적으로 recordTimerActivity를 호출하여 구현
  Future<Result<void>> startMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  );

  /// 특정 시간으로 타이머 일시정지 기록
  /// 내부적으로 recordTimerActivity를 호출하여 구현
  Future<Result<void>> pauseMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  );

  /// 특정 시간으로 타이머 재개 기록
  /// 내부적으로 recordTimerActivity를 호출하여 구현
  Future<Result<void>> resumeMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  );

  /// 특정 시간으로 타이머 종료 기록
  /// 내부적으로 recordTimerActivity를 호출하여 구현
  Future<Result<void>> stopMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  );

  // 캐시된 멤버 정보 가져오기
  Result<List<GroupMember>> getCachedGroupMembers(String groupId);

  // 멤버 정보 캐시에 저장
  void cacheGroupMembers(String groupId, List<GroupMember> members);

  // 캐시 무효화
  void invalidateGroupMemberCache(String groupId);
}
