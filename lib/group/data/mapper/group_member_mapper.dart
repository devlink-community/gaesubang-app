// lib/group/data/mapper/group_member_mapper.dart
import 'package:devlink_mobile_app/group/data/dto/group_member_dto.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';
import 'package:devlink_mobile_app/group/domain/model/timer_activity_type.dart';

extension GroupMemberDtoMapper on GroupMemberDto {
  /// DTO를 모델로 변환
  GroupMember toModel() {
    // String 타입의 timerState를 TimerActivityType으로 변환
    TimerActivityType timerStateEnum;

    if (timerState == null) {
      timerStateEnum = TimerActivityType.end;
    } else {
      try {
        timerStateEnum = TimerActivityType.fromString(timerState!);
      } catch (_) {
        timerStateEnum = TimerActivityType.end;
      }
    }

    return GroupMember(
      id: id ?? '',
      userId: userId ?? '',
      userName: userName ?? '',
      profileUrl: profileUrl,
      role: role ?? 'member',
      joinedAt: joinedAt ?? DateTime.now(),
      timerState: timerStateEnum,
      timerStartAt: timerStartAt,
      timerLastUpdatedAt: timerLastUpdatedAt,
      timerElapsed: timerElapsed ?? 0,
      timerTodayDuration: timerTodayDuration ?? 0,
      timerMonthlyDurations: timerMonthlyDurations?.cast<String, int>() ?? {},
      timerTotalDuration: timerTotalDuration ?? 0,
      timerPauseExpiryTime: timerPauseExpiryTime,
    );
  }
}

extension GroupMemberDtoListMapper on List<GroupMemberDto>? {
  /// DTO 리스트를 모델 리스트로 변환
  List<GroupMember> toModelList() {
    if (this == null || this!.isEmpty) return [];
    return this!.map((dto) => dto.toModel()).toList();
  }
}
