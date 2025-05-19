import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'timer_activity_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class TimerActivityDto {
  const TimerActivityDto({
    this.memberId,
    this.type,
    this.timestamp,
    this.metadata,
  });

  final String? memberId;
  final String? type; // "start", "pause", "resume", "end"
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? timestamp;
  final Map<String, dynamic>? metadata;

  factory TimerActivityDto.fromJson(Map<String, dynamic> json) =>
      _$TimerActivityDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TimerActivityDtoToJson(this);
}

// Timestamp 변환 유틸리티 함수
DateTime? _timestampFromJson(dynamic value) {
  if (value == null) return null;

  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  return null;
}

dynamic _timestampToJson(DateTime? dateTime) {
  if (dateTime == null) return null;
  return Timestamp.fromDate(dateTime);
}
