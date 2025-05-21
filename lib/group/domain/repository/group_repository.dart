import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/attendance.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';

abstract interface class GroupRepository {
  Future<Result<List<Group>>> getGroupList();
  Future<Result<Group>> getGroupDetail(String groupId);
  Future<Result<void>> joinGroup(String groupId);
  Future<Result<Group>> createGroup(Group group);
  Future<Result<void>> updateGroup(Group group);
  Future<Result<void>> leaveGroup(String groupId);
  Future<Result<List<Group>>> searchGroups(String query);

  Future<Result<Map<String, dynamic>>> startMemberTimer(
    String groupId,
    String memberId,
    String memberName,
  );
  Future<Result<Map<String, dynamic>>> stopMemberTimer(
    String groupId,
    String memberId,
    String memberName,
  );
  Future<Result<Map<String, dynamic>>> pauseMemberTimer(
    String groupId,
    String memberId,
    String memberName,
  );

  /// 그룹 멤버 목록과 해당 타이머 상태 조회
  Future<Result<List<GroupMember>>> getGroupMembers(String groupId);

  /// 특정 그룹의 특정 월 출석 기록 조회
  Future<Result<List<Attendance>>> getAttendancesByMonth(
    String groupId,
    int year,
    int month,
  );
}
