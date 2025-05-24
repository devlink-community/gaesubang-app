// lib/group/data/dto/group_member_activity_dto.dart
import 'package:devlink_mobile_app/core/utils/firebase_timestamp_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_member_activity_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class GroupMemberActivityDto {
  const GroupMemberActivityDto({
    this.state,
    this.startAt,
    this.lastUpdatedAt,
    this.elapsed,
    this.todayDuration,
    this.monthlyDurations,
    this.totalDuration,
  });

  /// 타이머 상태 ("running", "paused", "idle")
  final String? state;

  /// 현재 세션 시작 시간 (running 상태일 때만 유효)
  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? startAt;

  /// 마지막 업데이트 시간
  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? lastUpdatedAt;

  /// 현재 세션 누적 초 (paused 상태일 때)
  final int? elapsed;

  /// 오늘 총 누적 시간 (초)
  final int? todayDuration;

  /// 일자별 누적 시간 (초)
  final Map<String, int>? monthlyDurations;

  /// 전체 누적 시간 (초)
  final int? totalDuration;

  factory GroupMemberActivityDto.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberActivityDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GroupMemberActivityDtoToJson(this);

  GroupMemberActivityDto copyWith({
    String? state,
    DateTime? startAt,
    DateTime? lastUpdatedAt,
    int? elapsed,
    int? todayDuration,
    Map<String, int>? monthlyDurations,
    int? totalDuration,
  }) {
    return GroupMemberActivityDto(
      state: state ?? this.state,
      startAt: startAt ?? this.startAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      elapsed: elapsed ?? this.elapsed,
      todayDuration: todayDuration ?? this.todayDuration,
      monthlyDurations: monthlyDurations ?? this.monthlyDurations,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }
}
