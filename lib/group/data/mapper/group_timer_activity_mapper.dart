// lib/group/data/mapper/group_timer_activity_mapper.dart
import 'package:devlink_mobile_app/group/data/dto/group_timer_activity_dto.dart';
import 'package:devlink_mobile_app/group/domain/model/group_timer_activity.dart';

/// GroupTimerActivityDto → GroupTimerActivity 변환
extension GroupTimerActivityDtoMapper on GroupTimerActivityDto {
  GroupTimerActivity toModel() {
    return GroupTimerActivity(
      id: id ?? '',
      memberId: memberId ?? '',
      memberName: memberName ?? '',
      type: type ?? '',
      timestamp: timestamp ?? DateTime.now(),
      groupId: groupId ?? '',
      metadata: metadata,
    );
  }
}

/// GroupTimerActivity → GroupTimerActivityDto 변환
extension GroupTimerActivityModelMapper on GroupTimerActivity {
  GroupTimerActivityDto toDto() {
    return GroupTimerActivityDto(
      id: id,
      memberId: memberId,
      memberName: memberName,
      type: type,
      timestamp: timestamp,
      groupId: groupId,
      metadata: metadata,
    );
  }
}

/// List<GroupTimerActivityDto> → List<GroupTimerActivity> 변환
extension GroupTimerActivityDtoListMapper on List<GroupTimerActivityDto>? {
  List<GroupTimerActivity> toModelList() =>
      this?.map((e) => e.toModel()).toList() ?? [];
}

/// List<GroupTimerActivity> → List<GroupTimerActivityDto> 변환
extension GroupTimerActivityModelListMapper on List<GroupTimerActivity> {
  List<GroupTimerActivityDto> toDtoList() => map((e) => e.toDto()).toList();
}

/// Map<String, dynamic> → GroupTimerActivityDto 변환
extension MapToGroupTimerActivityDtoMapper on Map<String, dynamic> {
  GroupTimerActivityDto toGroupTimerActivityDto() =>
      GroupTimerActivityDto.fromJson(this);
}
