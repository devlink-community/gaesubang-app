import 'package:devlink_mobile_app/core/utils/firebase_timestamp_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_timer_activity_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class GroupTimerActivityDto {
  const GroupTimerActivityDto({
    this.memberId,
    this.type,
    this.timestamp,
    this.metadata,
  });

  final String? memberId;
  final String? type; // "start", "pause", "resume", "end"
  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? timestamp;
  final Map<String, dynamic>? metadata;

  factory GroupTimerActivityDto.fromJson(Map<String, dynamic> json) =>
      _$GroupTimerActivityDtoFromJson(json);
  Map<String, dynamic> toJson() => _$GroupTimerActivityDtoToJson(this);
}
