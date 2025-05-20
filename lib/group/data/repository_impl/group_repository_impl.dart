// lib/group/data/repository_impl/group_repository_impl.dart
import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/data/data_source/group_data_source.dart';
import 'package:devlink_mobile_app/group/data/dto/group_dto.dart';
import 'package:devlink_mobile_app/group/data/dto/group_member_dto.dart';
import 'package:devlink_mobile_app/group/data/dto/group_timer_activity_dto.dart';
import 'package:devlink_mobile_app/group/data/mapper/group_mapper.dart';
import 'package:devlink_mobile_app/group/data/mapper/group_member_mapper.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupDataSource _dataSource;
  final Ref _ref;

  GroupRepositoryImpl({required GroupDataSource dataSource, required Ref ref})
    : _dataSource = dataSource,
      _ref = ref;

  @override
  Future<Result<List<Group>>> getGroupList() async {
    try {
      // 현재 사용자 정보 확인
      final currentUser = _ref.read(currentUserProvider);

      // 사용자가 가입한 그룹 ID 목록 확인
      Set<String> joinedGroupIds = {};
      if (currentUser != null) {
        // currentUser.joinedGroups에서 그룹 ID 추출
        for (final joinedGroup in currentUser.joinedGroups) {
          if (joinedGroup.groupId != null) {
            joinedGroupIds.add(joinedGroup.groupId!);
          }
        }
      }

      // 데이터소스에 가입 그룹 ID 전달
      final groupsData = await _dataSource.fetchGroupList(
        joinedGroupIds: joinedGroupIds.isNotEmpty ? joinedGroupIds : null,
      );

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
      // 현재 사용자 정보 확인
      final currentUser = _ref.read(currentUserProvider);

      // 사용자의 그룹 가입 여부 확인
      bool? isJoined = false;
      if (currentUser != null) {
        // currentUser.joinedGroups에서 현재 그룹 ID 확인
        isJoined = currentUser.joinedGroups.any(
          (group) => group.groupId == groupId,
        );
      }

      // 데이터소스에 가입 여부 전달
      final groupData = await _dataSource.fetchGroupDetail(
        groupId,
        isJoined: isJoined,
      );

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
      // Auth에서 현재 사용자 정보 가져오기
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) {
        return Result.error(
          Failure(
            FailureType.unauthorized,
            '로그인이 필요합니다.',
            stackTrace: StackTrace.current,
          ),
        );
      }

      // 이미 가입된 그룹인지 확인 (클라이언트 측에서 확인, API 호출 없음)
      final isAlreadyJoined = currentUser.joinedGroups.any(
        (group) => group.groupId == groupId,
      );

      if (isAlreadyJoined) {
        return Result.error(
          Failure(
            FailureType.validation,
            '이미 가입한 그룹입니다.',
            stackTrace: StackTrace.current,
          ),
        );
      }

      // 그룹 가입 처리
      await _dataSource.fetchJoinGroup(
        groupId,
        userId: currentUser.id,
        userName: currentUser.nickname,
        profileUrl: currentUser.image,
      );

      return const Result.success(null);
    } catch (e, st) {
      // 특정 에러 타입 구분
      if (e.toString().contains('이미 가입한 그룹입니다')) {
        return Result.error(
          Failure(
            FailureType.validation,
            '이미 가입한 그룹입니다.',
            cause: e,
            stackTrace: st,
          ),
        );
      } else if (e.toString().contains('그룹 최대 인원에 도달했습니다')) {
        return Result.error(
          Failure(
            FailureType.validation,
            '그룹 최대 인원에 도달했습니다.',
            cause: e,
            stackTrace: st,
          ),
        );
      } else if (e.toString().contains('그룹을 찾을 수 없습니다')) {
        return Result.error(
          Failure(
            FailureType.server,
            '그룹을 찾을 수 없습니다.',
            cause: e,
            stackTrace: st,
          ),
        );
      }

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

  @override
  Future<Result<List<GroupMember>>> getGroupMembersWithTimerStatus(
    String groupId,
  ) async {
    try {
      // 1. 그룹 멤버 정보 조회
      final membersData = await _dataSource.fetchGroupMembers(groupId);
      final memberDtos =
          membersData.map((data) => GroupMemberDto.fromJson(data)).toList();

      // 2. 타이머 활동 정보 조회
      final timerActivitiesData = await _dataSource.fetchGroupTimerActivities(
        groupId,
      );
      final timerActivityDtos =
          timerActivitiesData
              .map((data) => GroupTimerActivityDto.fromJson(data))
              .toList();

      // 3. 멤버와 타이머 활동 정보 결합
      final groupMembers = memberDtos.toModelList(timerActivityDtos);

      return Result.success(groupMembers);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }
}
