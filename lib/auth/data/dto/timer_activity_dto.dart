import 'package:devlink_mobile_app/core/utils/firebase_timestamp_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'timer_activity_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class TimerActivityDto {
  const TimerActivityDto({
    this.id,
    this.userId,
    this.type,
    this.timestamp,
    this.metadata,
  });

  final String? id;
  final String? userId;
  final String? type; // "start", "pause", "resume", "end"
  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? timestamp;
  final Map<String, dynamic>? metadata;

  factory TimerActivityDto.fromJson(Map<String, dynamic> json) =>
      _$TimerActivityDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TimerActivityDtoToJson(this);
}
