// lib/group/data/mapper/group_member_mapper.dart
import 'package:devlink_mobile_app/group/data/dto/group_member_dto.dart';
import 'package:devlink_mobile_app/group/data/dto/group_timer_activity_dto.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';

extension GroupMemberDtoMapper on GroupMemberDto {
  /// DTO를 모델로 변환 (타이머 상태 포함)
  GroupMember toModel(GroupTimerActivityDto? timerActivity) {
    // 타이머 활동에 따라 isActive 설정
    // start 또는 resume인 경우 활성화
    final isActive =
        timerActivity?.type == 'start' || timerActivity?.type == 'resume';

    DateTime? startTime;
    int elapsedMinutes = 0;
    int elapsedSeconds = 0;

    // 활성 상태인 경우 시작 시간과 경과 시간 계산
    if (isActive && timerActivity?.timestamp != null) {
      startTime = timerActivity?.timestamp;
      final now = DateTime.now();
      elapsedSeconds = now.difference(startTime!).inSeconds;
      elapsedMinutes = (elapsedSeconds / 60).floor();
    }

    return GroupMember(
      id: id ?? '',
      userId: userId ?? '',
      userName: userName ?? '',
      profileUrl: profileUrl,
      role: role ?? 'member',
      joinedAt: joinedAt ?? DateTime.now(),
      isActive: isActive,
      timerStartTime: startTime,
      elapsedMinutes: elapsedMinutes,
      elapsedSeconds: elapsedSeconds,
    );
  }
}

extension GroupMemberDtoListMapper on List<GroupMemberDto>? {
  /// DTO 리스트를 모델 리스트로 변환 (타이머 활동 정보 포함)
  List<GroupMember> toModelList(List<GroupTimerActivityDto> timerActivities) {
    if (this == null || this!.isEmpty) return [];

    // 멤버ID로 타이머 활동 매핑
    final timerMap = <String, GroupTimerActivityDto>{};

    // 각 멤버의 가장 최근 타이머 활동 찾기
    for (final activity in timerActivities) {
      final userId = activity.userId;
      if (userId == null) continue;

      // 이미 해당 멤버의 활동이 있고, 현재 활동이 더 오래된 경우 스킵
      if (timerMap.containsKey(userId) &&
          activity.timestamp != null &&
          timerMap[userId]!.timestamp != null &&
          activity.timestamp!.isBefore(timerMap[userId]!.timestamp!)) {
        continue;
      }

      timerMap[userId] = activity;
    }

    // 각 멤버를 타이머 상태와 함께 변환
    return this!.map((dto) {
      final userId = dto.userId;
      final timerActivity = userId != null ? timerMap[userId] : null;
      return dto.toModel(timerActivity);
    }).toList();
  }
}
