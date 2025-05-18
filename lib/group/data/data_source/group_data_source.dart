import '../dto/group_dto_old.dart';

abstract interface class GroupDataSource {
  Future<List<GroupDto>> fetchGroupList();
  Future<GroupDto> fetchGroupDetail(String groupId);
  Future<void> fetchJoinGroup(String groupId);
  Future<GroupDto> fetchCreateGroup(GroupDto groupDto);
  Future<void> fetchUpdateGroup(GroupDto groupDto);
  Future<void> fetchLeaveGroup(String groupId);
  Future<List<GroupDto>> fetchUserJoinedGroups(String userId);
}
