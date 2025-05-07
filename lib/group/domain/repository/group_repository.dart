import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domin/model/group.dart';

abstract interface class GroupRepository {
  Future<Result<List<Group>>> getGroupList();
  Future<Result<Group>> getGroupDetail(String groupId);
  Future<Result<void>> joinGroup(String groupId);
  Future<Result<Group>> createGroup(Group group);
  Future<Result<void>> updateGroup(Group group);
  Future<Result<void>> leaveGroup(String groupId);
}
