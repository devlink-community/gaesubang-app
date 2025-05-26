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

    // timerMonthlyDurations를 안전하게 처리
    final cleanedMonthly = <String, int>{};
    if (timerMonthlyDurations != null) {
      timerMonthlyDurations!.forEach((k, dynamic v) {
        // 타입을 dynamic으로 지정
        if (v is int) {
          cleanedMonthly[k] = v;
        } else if (v is num) {
          cleanedMonthly[k] = v.toInt();
        } else {
          cleanedMonthly[k] = 0;
        }
      });
    }

    return GroupMember(
      id: id ?? '',
      userId: userId ?? '',
      userName: userName ?? '',
      profileUrl: profileUrl,
      role: role ?? 'member',
      joinedAt: joinedAt ?? TimeFormatter.nowInSeoul(),
      timerState: timerStateEnum,
      timerStartAt: timerStartAt,
      timerLastUpdatedAt: timerLastUpdatedAt,
      timerElapsed: timerElapsed ?? 0,
      timerTodayDuration: timerTodayDuration ?? 0,
      timerMonthlyDurations: cleanedMonthly,
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
