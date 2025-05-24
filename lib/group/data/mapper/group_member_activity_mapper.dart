// lib/group/data/mapper/group_member_activity_mapper.dart
import 'package:devlink_mobile_app/group/data/dto/group_member_activity_dto.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member_activity.dart';

/// GroupMemberActivityDto → GroupMemberActivity 변환
extension GroupMemberActivityDtoMapper on GroupMemberActivityDto {
  GroupMemberActivity toModel() {
    return GroupMemberActivity(
      state: state ?? 'idle',
      startAt: startAt,
      lastUpdatedAt: lastUpdatedAt ?? DateTime.now(),
      elapsed: elapsed ?? 0,
      todayDuration: todayDuration ?? 0,
      monthlyDurations: monthlyDurations ?? {},
      totalDuration: totalDuration ?? 0,
    );
  }
}

/// GroupMemberActivity → GroupMemberActivityDto 변환
extension GroupMemberActivityModelMapper on GroupMemberActivity {
  GroupMemberActivityDto toDto() {
    return GroupMemberActivityDto(
      state: state,
      startAt: startAt,
      lastUpdatedAt: lastUpdatedAt,
      elapsed: elapsed,
      todayDuration: todayDuration,
      monthlyDurations: monthlyDurations,
      totalDuration: totalDuration,
    );
  }
}

/// Map<String, dynamic> → GroupMemberActivityDto 변환
extension MapToGroupMemberActivityDtoMapper on Map<String, dynamic> {
  GroupMemberActivityDto toGroupMemberActivityDto() =>
      GroupMemberActivityDto.fromJson(this);
}

/// List<GroupMemberActivityDto> → List<GroupMemberActivity> 변환
extension GroupMemberActivityDtoListMapper on List<GroupMemberActivityDto>? {
  List<GroupMemberActivity> toModelList() =>
      this?.map((e) => e.toModel()).toList() ?? [];
}
