// lib/group/data/repository_impl/group_repository_impl.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/group/data/data_source/group_data_source.dart';
import 'package:devlink_mobile_app/group/data/dto/group_dto.dart';
import 'package:devlink_mobile_app/group/data/dto/group_member_dto.dart';
import 'package:devlink_mobile_app/group/data/mapper/group_mapper.dart';
import 'package:devlink_mobile_app/group/data/mapper/group_member_mapper.dart';
import 'package:devlink_mobile_app/group/domain/model/attendance.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';
import 'package:devlink_mobile_app/group/domain/model/timer_activity_type.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupDataSource _dataSource;

  GroupRepositoryImpl({required GroupDataSource dataSource})
    : _dataSource = dataSource;

  // 그룹 ID별 멤버 정보 캐시
  static final Map<String, List<GroupMember>> _memberCache = {};

  // 캐시 타임스탬프
  static final Map<String, DateTime> _memberCacheTimestamp = {};

  // 최대 캐시 유지 시간 (분 단위)
  static const int _maxCacheAgeMinutes = 30;

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
      // 그룹 멤버 정보 조회
      final membersData = await _dataSource.fetchGroupMembers(groupId);

      // DTO 변환 및 모델 변환
      final memberDtos =
          membersData.map((data) => GroupMemberDto.fromJson(data)).toList();
      final members = memberDtos.toModelList();

      // 멤버 정보를 캐시에 저장
      cacheGroupMembers(groupId, members);

      return Result.success(members);
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

  @override
  Stream<Result<List<GroupMember>>> streamGroupMemberTimerStatus(
    String groupId,
  ) {
    return _dataSource.streamGroupMemberTimerStatus(groupId).map((
      combinedData,
    ) {
      try {
        // 새 구조에서는 멤버 문서에 타이머 상태가 포함됨
        final List<GroupMemberDto> memberDtos = [];

        for (final item in combinedData) {
          // 멤버 DTO 추출
          final memberData = item['memberDto'] as Map<String, dynamic>;
          memberDtos.add(GroupMemberDto.fromJson(memberData));
        }

        // 멤버 목록 변환
        final groupMembers = memberDtos.toModelList();

        AppLogger.info(
          '실시간 멤버 상태 변환 완료: ${groupMembers.length}명',
          tag: 'GroupRepository',
        );

        return Result<List<GroupMember>>.success(groupMembers);
      } catch (e, st) {
        AppLogger.error(
          '실시간 멤버 상태 변환 실패',
          tag: 'GroupRepository',
          error: e,
          stackTrace: st,
        );
        return Result<List<GroupMember>>.error(
          mapExceptionToFailure(e, st),
        );
      }
    });
  }

  @override
  Future<Result<void>> recordTimerActivity(
    String groupId,
    TimerActivityType activityType, {
    DateTime? timestamp,
  }) async {
    try {
      // 타임스탬프가 없으면 현재 시간 사용
      final actualTimestamp = timestamp ?? DateTime.now();

      // DataSource에서 직접 타이머 활동 기록
      await _dataSource.recordTimerActivityWithTimestamp(
        groupId,
        activityType,
        actualTimestamp,
      );

      return const Result.success(null);
    } catch (e, st) {
      // 특정 오류 타입 처리 (필요한 경우)
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
  Future<Result<void>> startMemberTimer(String groupId) async {
    return recordTimerActivity(groupId, TimerActivityType.start);
  }

  @override
  Future<Result<void>> pauseMemberTimer(String groupId) async {
    return recordTimerActivity(groupId, TimerActivityType.pause);
  }

  @override
  Future<Result<void>> resumeMemberTimer(String groupId) async {
    return recordTimerActivity(groupId, TimerActivityType.resume);
  }

  @override
  Future<Result<void>> stopMemberTimer(String groupId) async {
    return recordTimerActivity(groupId, TimerActivityType.end);
  }

  @override
  Future<Result<List<Attendance>>> getAttendancesByMonth(
    String groupId,
    int year,
    int month,
  ) async {
    try {
      // 1. 월별 출석 데이터 조회
      final attendanceData = await _dataSource.fetchMonthlyAttendances(
        groupId,
        year,
        month,
      );

      // 2. 출석 데이터를 Attendance 모델로 변환
      final List<Attendance> attendances = [];

      // 출석 데이터가 없으면 빈 리스트 반환
      if (attendanceData.isEmpty) {
        return Result.success(<Attendance>[]);
      }

      // 3. 캐시된 멤버 정보 조회
      final memberResult = getCachedGroupMembers(groupId);
      final Map<String, GroupMember> memberMap = {};

      // 캐시된 멤버 정보가 있으면 Map으로 변환 (userId를 키로)
      if (memberResult is Success<List<GroupMember>>) {
        for (final member in memberResult.data) {
          memberMap[member.userId] = member;
        }
      }

      // 4. 출석 데이터를 Attendance 모델로 변환
      for (final data in attendanceData) {
        final userId = data['userId'] as String?;
        if (userId == null) continue;

        final dateStr = data['date'] as String?;
        if (dateStr == null) continue;

        // 날짜 파싱
        DateTime date;
        try {
          date = DateTime.parse(dateStr);
        } catch (e) {
          AppLogger.warning(
            '날짜 파싱 실패: $dateStr',
            tag: 'GroupRepositoryImpl',
            error: e,
          );
          continue;
        }

        // 초 단위를 분 단위로 변환 (60으로 나눔)
        final timeInSeconds = data['timeInSeconds'] as int? ?? 0;
        final timeInMinutes = timeInSeconds ~/ 60;

        // 멤버 정보 조회 (캐시에 있으면 사용, 없으면 기본값)
        String userName = 'Unknown';
        String? profileUrl;

        final member = memberMap[userId];
        if (member != null) {
          userName = member.userName;
          profileUrl = member.profileUrl;
        }

        // Attendance 객체 생성
        attendances.add(
          Attendance(
            groupId: groupId,
            userId: userId,
            userName: userName,
            profileUrl: profileUrl,
            date: date,
            timeInMinutes: timeInMinutes,
          ),
        );
      }

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
    TimerActivityType activityType,
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
    return recordTimerActivityWithTimestamp(
      groupId,
      TimerActivityType.start,
      timestamp,
    );
  }

  @override
  Future<Result<void>> pauseMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return recordTimerActivityWithTimestamp(
      groupId,
      TimerActivityType.pause,
      timestamp,
    );
  }

  @override
  Future<Result<void>> stopMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return recordTimerActivityWithTimestamp(
      groupId,
      TimerActivityType.end,
      timestamp,
    );
  }

  @override
  Future<Result<void>> resumeMemberTimerWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return recordTimerActivity(
      groupId,
      TimerActivityType.resume,
      timestamp: timestamp,
    );
  }

  @override
  Result<List<GroupMember>> getCachedGroupMembers(String groupId) {
    final cachedMembers = _memberCache[groupId];
    final cachedTime = _memberCacheTimestamp[groupId];

    // 캐시가 없는 경우
    if (cachedMembers == null || cachedTime == null) {
      return const Result.error(
        Failure(
          FailureType.notFound,
          '캐시된 멤버 정보가 없습니다.',
        ),
      );
    }

    // 캐시 만료 확인
    final now = DateTime.now();
    final cacheAge = now.difference(cachedTime).inMinutes;
    if (cacheAge > _maxCacheAgeMinutes) {
      // 캐시 삭제
      _memberCache.remove(groupId);
      _memberCacheTimestamp.remove(groupId);

      return const Result.error(
        Failure(
          FailureType.notFound,
          '캐시된 멤버 정보가 만료되었습니다.',
        ),
      );
    }

    // 캐시된 멤버 정보 복사본 반환
    return Result.success(List.from(cachedMembers));
  }

  @override
  void cacheGroupMembers(String groupId, List<GroupMember> members) {
    _memberCache[groupId] = List.from(members);
    _memberCacheTimestamp[groupId] = DateTime.now();

    AppLogger.debug(
      '그룹 멤버 정보 캐시됨: $groupId (${members.length}명)',
      tag: 'GroupRepositoryImpl',
    );
  }

  @override
  void invalidateGroupMemberCache(String groupId) {
    _memberCache.remove(groupId);
    _memberCacheTimestamp.remove(groupId);

    AppLogger.debug(
      '그룹 멤버 캐시 무효화: $groupId',
      tag: 'GroupRepositoryImpl',
    );
  }
}
