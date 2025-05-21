// lib/group/data/repository_impl/group_repository_impl.dart
import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/focus_stats_calculator.dart';
import 'package:devlink_mobile_app/group/data/data_source/group_data_source.dart';
import 'package:devlink_mobile_app/group/data/dto/group_dto.dart';
import 'package:devlink_mobile_app/group/data/dto/group_member_dto.dart';
import 'package:devlink_mobile_app/group/data/dto/group_timer_activity_dto.dart';
import 'package:devlink_mobile_app/group/data/mapper/group_mapper.dart';
import 'package:devlink_mobile_app/group/data/mapper/group_member_mapper.dart';
import 'package:devlink_mobile_app/group/domain/model/attendance.dart';
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

      // Group → GroupDto → Map<String, dynamic> 변환
      final groupDto = group.toDto();
      final groupData = groupDto.toJson();

      // 사용자 정보 전달 (ownerNickname, ownerProfileImage 추가)
      final createdGroupData = await _dataSource.fetchCreateGroup(
        groupData,
        ownerId: currentUser.id,
        ownerNickname: currentUser.nickname,
        ownerProfileUrl: currentUser.image,
      );

      // Map<String, dynamic> → GroupDto → Group 변환
      final createdGroupDto = GroupDto.fromJson(createdGroupData);
      final createdGroup = createdGroupDto.toModel();

      return Result.success(createdGroup);
    } catch (e, st) {
      // 특정 에러 타입 구분
      if (e.toString().contains('그룹 생성에 실패했습니다')) {
        return Result.error(
          Failure(
            FailureType.server,
            '그룹 생성에 실패했습니다.',
            cause: e,
            stackTrace: st,
          ),
        );
      }

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

      // Group → GroupDto → Map<String, dynamic> 변환
      final groupDto = group.toDto();
      final groupData = groupDto.toJson();

      await _dataSource.fetchUpdateGroup(group.id, groupData);

      return const Result.success(null);
    } catch (e, st) {
      // 특정 에러 타입 구분
      if (e.toString().contains('그룹을 찾을 수 없습니다')) {
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

      // 그룹 탈퇴 처리
      await _dataSource.fetchLeaveGroup(groupId, currentUser.id);

      return const Result.success(null);
    } catch (e, st) {
      // 특정 에러 타입 구분
      if (e.toString().contains('그룹 소유자는 탈퇴할 수 없습니다')) {
        return Result.error(
          Failure(
            FailureType.validation,
            '그룹 소유자는 탈퇴할 수 없습니다. 그룹을 삭제하거나 소유권을 이전하세요.',
            cause: e,
            stackTrace: st,
          ),
        );
      } else if (e.toString().contains('해당 그룹의 멤버가 아닙니다')) {
        return Result.error(
          Failure(
            FailureType.validation,
            '해당 그룹의 멤버가 아닙니다.',
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
      // 현재 사용자 정보 가져오기
      final currentUser = _ref.read(currentUserProvider);

      // 사용자가 가입한 그룹 ID 집합을 생성합니다.
      Set<String> joinedGroupIds = {};
      if (currentUser != null) {
        // currentUser.joinedGroups에서 그룹 ID 추출
        for (final joinedGroup in currentUser.joinedGroups) {
          if (joinedGroup.groupId != null) {
            joinedGroupIds.add(joinedGroup.groupId!);
          }
        }
      }

      // 통합 검색 API 사용 - currentUserId 대신 joinedGroupIds 전달
      final groupsData = await _dataSource.searchGroups(
        query,
        searchKeywords: true,
        searchTags: true,
        joinedGroupIds: joinedGroupIds.isNotEmpty ? joinedGroupIds : null,
        sortBy: 'name', // 기본 정렬 기준 설정
        // limit: 20, // 필요시 결과 제한
      );

      // Map<String, dynamic> → GroupDto → Group 변환
      final groupDtos =
          groupsData.map((data) => GroupDto.fromJson(data)).toList();
      final groups = groupDtos.toModelList();

      return Result.success(groups);
    } catch (e, st) {
      // 구체적인 에러 유형에 따라 다른 Failure 반환
      if (e.toString().contains('검색 오류')) {
        return Result.error(
          Failure(
            FailureType.server,
            '검색 서비스에 문제가 발생했습니다.',
            cause: e,
            stackTrace: st,
          ),
        );
      }

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
  Future<Result<List<GroupMember>>> getGroupMembers(String groupId) async {
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

  @override
  Future<Result<void>> startMemberTimer(String groupId) async {
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

      // 타이머 시작 처리
      await _dataSource.startMemberTimer(
        groupId,
        currentUser.id,
        currentUser.nickname,
      );

      return const Result.success(null);
    } catch (e, st) {
      // 특정 오류 타입 처리
      if (e.toString().contains('이미 진행 중인 타이머 세션이 있습니다')) {
        return Result.error(
          Failure(
            FailureType.validation,
            '이미 진행 중인 타이머 세션이 있습니다.',
            cause: e,
            stackTrace: st,
          ),
        );
      }

      return Result.error(
        Failure(
          FailureType.unknown,
          '타이머 시작에 실패했습니다.',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> stopMemberTimer(String groupId) async {
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

      // 타이머 정지 처리
      await _dataSource.stopMemberTimer(
        groupId,
        currentUser.id,
        currentUser.nickname,
      );

      return const Result.success(null);
    } catch (e, st) {
      // 특정 오류 타입 처리
      if (e.toString().contains('타이머가 활성화되어 있지 않습니다')) {
        return Result.error(
          Failure(
            FailureType.validation,
            '타이머가 활성화되어 있지 않습니다.',
            cause: e,
            stackTrace: st,
          ),
        );
      }

      return Result.error(
        Failure(
          FailureType.unknown,
          '타이머 정지에 실패했습니다.',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> pauseMemberTimer(String groupId) async {
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

      // 타이머 일시정지 처리
      await _dataSource.pauseMemberTimer(
        groupId,
        currentUser.id,
        currentUser.nickname,
      );

      return const Result.success(null);
    } catch (e, st) {
      // 특정 오류 타입 처리
      if (e.toString().contains('타이머가 활성화되어 있지 않습니다')) {
        return Result.error(
          Failure(
            FailureType.validation,
            '타이머가 활성화되어 있지 않습니다.',
            cause: e,
            stackTrace: st,
          ),
        );
      }

      return Result.error(
        Failure(
          FailureType.unknown,
          '타이머 일시정지에 실패했습니다.',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<Attendance>>> getAttendancesByMonth(
    String groupId,
    int year,
    int month,
  ) async {
    try {
      // 1. 월간 타이머 활동 데이터 조회
      final activitiesData = await _dataSource.fetchMonthlyAttendances(
        groupId,
        year,
        month,
      );

      // 2. 유틸리티를 사용하여 출석 기록 계산
      final attendances =
          FocusStatsCalculator.calculateAttendancesFromActivities(
            groupId,
            activitiesData,
          );

      return Result.success(attendances);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }
}
