// lib/group/data/dto/group_timer_activity_dto.dart
import 'package:devlink_mobile_app/core/utils/firebase_timestamp_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_timer_activity_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class GroupTimerActivityDto {
  const GroupTimerActivityDto({
    this.id,
    this.memberId,
    this.memberName,
    this.type,
    this.timestamp,
    this.groupId,
    this.metadata,
  });

  final String? id;
  final String? memberId;
  final String? memberName;
  final String? type; // "start", "end" 등 타이머 액션 타입
  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? timestamp;
  final String? groupId;
  final Map<String, dynamic>? metadata;

  factory GroupTimerActivityDto.fromJson(Map<String, dynamic> json) =>
      _$GroupTimerActivityDtoFromJson(json);
  Map<String, dynamic> toJson() => _$GroupTimerActivityDtoToJson(this);

  // 필드 업데이트를 위한 copyWith 메서드
  GroupTimerActivityDto copyWith({
    String? id,
    String? memberId,
    String? memberName,
    String? type,
    DateTime? timestamp,
    String? groupId,
    Map<String, dynamic>? metadata,
  }) {
    return GroupTimerActivityDto(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      groupId: groupId ?? this.groupId,
      metadata: metadata ?? this.metadata,
    );
  }
}
