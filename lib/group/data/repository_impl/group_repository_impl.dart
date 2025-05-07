import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/data/mepper/group_mepper.dart';
import 'package:devlink_mobile_app/group/domin/repository/group_repository.dart';
import 'package:devlink_mobile_app/group/domin/model/group.dart';

import '../data_source/group_data_source.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupDataSource _dataSource;

  GroupRepositoryImpl({required GroupDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Result<List<Group>>> getGroupList() async {
    try {
      final groupDtoList = await _dataSource.fetchGroupList();
      final groupList = groupDtoList.toModelList();
      return Result.success(groupList);
    } catch (e) {
      return Result.error(
        Failure(FailureType.unknown, '그룹 목록을 불러오는데 실패했습니다.', cause: e),
      );
    }
  }

  @override
  Future<Result<Group>> getGroupDetail(String groupId) async {
    try {
      final groupDto = await _dataSource.fetchGroupDetail(groupId);
      final group = groupDto.toModel();
      return Result.success(group);
    } catch (e) {
      return Result.error(
        Failure(FailureType.unknown, '그룹 정보를 불러오는데 실패했습니다.', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> joinGroup(String groupId) async {
    try {
      await _dataSource.fetchJoinGroup(groupId);
      return const Result.success(null);
    } catch (e) {
      return Result.error(
        Failure(FailureType.unknown, '그룹 참여에 실패했습니다.', cause: e),
      );
    }
  }

  @override
  Future<Result<Group>> createGroup(Group group) async {
    try {
      final groupDto = group.toDto();
      final createdGroupDto = await _dataSource.fetchCreateGroup(groupDto);
      final createdGroup = createdGroupDto.toModel();
      return Result.success(createdGroup);
    } catch (e) {
      return Result.error(
        Failure(FailureType.unknown, '그룹 생성에 실패했습니다.', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> updateGroup(Group group) async {
    try {
      final groupDto = group.toDto();
      await _dataSource.fetchUpdateGroup(groupDto);
      return const Result.success(null);
    } catch (e) {
      return Result.error(
        Failure(FailureType.unknown, '그룹 수정에 실패했습니다.', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> leaveGroup(String groupId) async {
    try {
      await _dataSource.fetchLeaveGroup(groupId);
      return const Result.success(null);
    } catch (e) {
      return Result.error(
        Failure(FailureType.unknown, '그룹 탈퇴에 실패했습니다.', cause: e),
      );
    }
  }
}
