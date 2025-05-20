// lib/group/data/repository_impl/group_repository_impl.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/data/data_source/group_data_source.dart';
import 'package:devlink_mobile_app/group/data/dto/group_dto.dart';
import 'package:devlink_mobile_app/group/data/mapper/group_mapper.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupDataSource _dataSource;

  GroupRepositoryImpl({required GroupDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Result<List<Group>>> getGroupList() async {
    try {
      // currentUserId를 null로 전달하면 모든 그룹을 가져옴
      final groupsData = await _dataSource.fetchGroupList();

      // Map<String, dynamic> → GroupDto → Group 변환
      final groupDtos =
          groupsData.map((data) => GroupDto.fromJson(data)).toList();
      final groups = groupDtos.toModelList();

      return Result.success(groups);
    } catch (e, st) {
      return Result.error(
        Failure(
          FailureType.unknown,
          '그룹 목록을 불러오는데 실패했습니다.',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<Group>>> getUserJoinedGroups(String userId) async {
    try {
      final groupsData = await _dataSource.fetchUserJoinedGroups(userId);

      // Map<String, dynamic> → GroupDto → Group 변환
      final groupDtos =
          groupsData.map((data) => GroupDto.fromJson(data)).toList();
      final groups = groupDtos.toModelList();

      return Result.success(groups);
    } catch (e, st) {
      return Result.error(
        Failure(
          FailureType.unknown,
          '사용자 가입 그룹 목록을 불러오는데 실패했습니다.',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Group>> getGroupDetail(String groupId) async {
    try {
      final groupData = await _dataSource.fetchGroupDetail(groupId);

      // Map<String, dynamic> → GroupDto → Group 변환
      final groupDto = GroupDto.fromJson(groupData);
      final group = groupDto.toModel();

      return Result.success(group);
    } catch (e, st) {
      return Result.error(
        Failure(
          FailureType.unknown,
          '그룹 정보를 불러오는데 실패했습니다.',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> joinGroup(String groupId) async {
    try {
      // 실제 구현에서는, 현재 사용자 정보를 가져와서 전달해야 함
      // 임시로 하드코딩된 값 사용
      await _dataSource.fetchJoinGroup(
        groupId,
        userId: 'currentUser',
        userName: '현재 사용자',
        profileUrl: '',
      );

      return const Result.success(null);
    } catch (e, st) {
      return Result.error(
        Failure(
          FailureType.unknown,
          '그룹 참여에 실패했습니다.',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Group>> createGroup(Group group) async {
    try {
      // Group → GroupDto → Map<String, dynamic> 변환
      final groupDto = group.toDto();
      final groupData = groupDto.toJson();

      // 실제 구현에서는 현재 사용자 정보를 가져와서 전달해야 함
      final createdGroupData = await _dataSource.fetchCreateGroup(
        groupData,
        ownerId: group.createdBy,
        ownerName: '그룹 생성자', // 실제로는 현재 사용자 이름
        ownerProfileUrl: '', // 실제로는 현재 사용자 프로필 URL
      );

      // Map<String, dynamic> → GroupDto → Group 변환
      final createdGroupDto = GroupDto.fromJson(createdGroupData);
      final createdGroup = createdGroupDto.toModel();

      return Result.success(createdGroup);
    } catch (e, st) {
      return Result.error(
        Failure(
          FailureType.unknown,
          '그룹 생성에 실패했습니다.',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> updateGroup(Group group) async {
    try {
      // Group → GroupDto → Map<String, dynamic> 변환
      final groupDto = group.toDto();
      final groupData = groupDto.toJson();

      await _dataSource.fetchUpdateGroup(group.id, groupData);

      return const Result.success(null);
    } catch (e, st) {
      return Result.error(
        Failure(
          FailureType.unknown,
          '그룹 수정에 실패했습니다.',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> leaveGroup(String groupId) async {
    try {
      // 실제 구현에서는 현재 사용자 ID를 가져와서 전달해야 함
      await _dataSource.fetchLeaveGroup(groupId, 'currentUser');

      return const Result.success(null);
    } catch (e, st) {
      return Result.error(
        Failure(
          FailureType.unknown,
          '그룹 탈퇴에 실패했습니다.',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<Group>>> searchGroups(String query) async {
    try {
      final keywordResults = await _dataSource.searchGroupsByKeyword(query);

      // 키워드가 해시태그일 수 있으므로 태그 검색도 시도
      final tagResults = await _dataSource.searchGroupsByTags([query]);

      // 두 결과 합치기 (중복 제거)
      final Map<String, Map<String, dynamic>> uniqueResults = {};

      // 키워드 검색 결과 추가
      for (final data in keywordResults) {
        final id = data['id'] as String;
        uniqueResults[id] = data;
      }

      // 태그 검색 결과 추가 (중복 없이)
      for (final data in tagResults) {
        final id = data['id'] as String;
        if (!uniqueResults.containsKey(id)) {
          uniqueResults[id] = data;
        }
      }

      // Map<String, dynamic> → GroupDto → Group 변환
      final groupDtos =
          uniqueResults.values.map((data) => GroupDto.fromJson(data)).toList();

      final groups = groupDtos.toModelList();

      return Result.success(groups);
    } catch (e, st) {
      return Result.error(
        Failure(
          FailureType.unknown,
          '그룹 검색 중 오류가 발생했습니다',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
