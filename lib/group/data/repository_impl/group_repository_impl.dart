// lib/group/data/repository_impl/group_repository_impl.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/focus_stats_calculator.dart';
import 'package:devlink_mobile_app/group/data/data_source/group_data_source.dart';
import 'package:devlink_mobile_app/group/data/dto/group_dto.dart';
import 'package:devlink_mobile_app/group/data/dto/group_member_dto.dart';
import 'package:devlink_mobile_app/group/data/dto/group_timer_activity_dto.dart';
import 'package:devlink_mobile_app/group/data/mapper/group_mapper.dart';
import 'package:devlink_mobile_app/group/data/mapper/group_member_mapper.dart';
import 'package:devlink_mobile_app/group/data/mapper/user_streak_mapper.dart';
import 'package:devlink_mobile_app/group/domain/model/attendance.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';
import 'package:devlink_mobile_app/group/domain/model/user_streak.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupDataSource _dataSource;

  GroupRepositoryImpl({required GroupDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Result<List<Group>>> getGroupList() async {
    try {
      // DataSource에서 직접 그룹 목록 조회 (내부에서 현재 사용자의 가입 정보 처리)
      final groupsData = await _dataSource.fetchGroupList();

      // 🔧 새로운 Mapper 사용: Map 리스트를 Group 리스트로 직접 변환
      final groups = groupsData.toGroupModelList();

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
      // DataSource에서 직접 그룹 상세 정보 조회 (내부에서 현재 사용자의 가입 여부 처리)
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
      // DataSource에서 직접 그룹 가입 처리 (내부에서 현재 사용자 정보 처리)
      await _dataSource.fetchJoinGroup(groupId);

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

      // DataSource에서 직접 그룹 생성 처리 (내부에서 현재 사용자를 소유자로 설정)
      final createdGroupData = await _dataSource.fetchCreateGroup(groupData);

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
      // DataSource에서 직접 그룹 탈퇴 처리 (내부에서 현재 사용자 정보 처리)
      await _dataSource.fetchLeaveGroup(groupId);

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
      // DataSource에서 직접 그룹 검색 (내부에서 현재 사용자의 가입 그룹 정보 처리)
      final groupsData = await _dataSource.searchGroups(
        query,
        searchKeywords: true,
        searchTags: true,
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
      return Result.error(
        Failure(
          FailureType.unknown,
          '그룹 멤버 정보를 불러오는데 실패했습니다.',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  // 🔧 새로운 실시간 스트림 메소드 - 기존 Mapper 활용
  @override
  Stream<Result<List<GroupMember>>> streamGroupMemberTimerStatus(
    String groupId,
  ) {
    return _dataSource.streamGroupMemberTimerStatus(groupId).map((
      combinedData,
    ) {
      try {
        // 🚀 DTO 분리
        final memberDtos = <GroupMemberDto>[];
        final timerActivityDtos = <GroupTimerActivityDto>[];

        for (final item in combinedData) {
          // 멤버 DTO 추출
          final memberData = item['memberDto'] as Map<String, dynamic>;
          memberDtos.add(GroupMemberDto.fromJson(memberData));

          // 타이머 활동 DTO 추출 (있는 경우만)
          final timerActivityData =
              item['timerActivityDto'] as Map<String, dynamic>?;
          if (timerActivityData != null) {
            timerActivityDtos.add(
              GroupTimerActivityDto.fromJson(timerActivityData),
            );
          }
        }

        // 🔧 기존 Mapper 사용
        final groupMembers = memberDtos.toModelList(timerActivityDtos);

        print('✅ 실시간 멤버 상태 변환 완료: ${groupMembers.length}명');

        return Result<List<GroupMember>>.success(groupMembers);
      } catch (e, st) {
        print('❌ 실시간 멤버 상태 변환 실패: $e');
        return Result<List<GroupMember>>.error(
          mapExceptionToFailure(e, st),
        );
      }
    });
  }

  @override
  Future<Result<void>> startMemberTimer(String groupId) async {
    try {
      // DataSource에서 직접 타이머 시작 처리 (내부에서 현재 사용자 정보 처리)
      await _dataSource.startMemberTimer(groupId);

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
      // DataSource에서 직접 타이머 정지 처리 (내부에서 현재 사용자 정보 처리)
      await _dataSource.stopMemberTimer(groupId);

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
      // DataSource에서 직접 타이머 일시정지 처리 (내부에서 현재 사용자 정보 처리)
      await _dataSource.pauseMemberTimer(groupId);

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
      return Result.error(
        Failure(
          FailureType.unknown,
          '출석 정보를 불러오는데 실패했습니다.',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
  // ===== 타임스탬프 지정 가능한 메서드들 추가 =====

  @override
  Future<Result<void>> recordTimerActivityWithTimestamp(
    String groupId,
    String activityType,
    DateTime timestamp,
  ) async {
    try {
      await _dataSource.recordTimerActivityWithTimestamp(
        groupId,
        activityType,
        timestamp,
      );

      return const Result.success(null);
    } catch (e, st) {
      // 특정 오류 타입 처리
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
          '타이머 활동 기록에 실패했습니다.',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> startMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return recordTimerActivityWithTimestamp(groupId, 'start', timestamp);
  }

  @override
  Future<Result<void>> pauseMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return recordTimerActivityWithTimestamp(groupId, 'pause', timestamp);
  }

  @override
  Future<Result<void>> stopMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return recordTimerActivityWithTimestamp(groupId, 'end', timestamp);
  }

  @override
  Future<Result<UserStreak>> getUserMaxStreakDays() async {
    try {
      // 1. 현재 사용자가 가입한 모든 그룹의 연속 출석일 정보 조회
      final userStreakData = await _dataSource.fetchUserMaxStreakDays();

      // 2. DTO → Model 변환
      final userStreakDto = userStreakData.toUserStreakDto();
      final userStreak = userStreakDto.toModel();

      return Result.success(userStreak);
    } catch (e, st) {
      return Result.error(
        Failure(
          FailureType.unknown,
          '연속 출석일을 불러오는데 실패했습니다.',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<int>> getWeeklyStudyTimeMinutes() async {
    try {
      // DataSource에서 이번 주 공부 시간 데이터 조회
      final weeklyStudyData = await _dataSource.fetchWeeklyStudyTimeMinutes();

      return Result.success(weeklyStudyData);
    } catch (e, st) {
      return Result.error(
        Failure(
          FailureType.unknown,
          '이번 주 공부 시간을 불러오는데 실패했습니다.',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
