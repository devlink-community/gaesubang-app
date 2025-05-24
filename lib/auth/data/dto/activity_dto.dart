// lib/auth/data/dto/activity_dto.dart
import 'package:devlink_mobile_app/core/utils/firebase_timestamp_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'activity_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class ActivityDto {
  const ActivityDto({
    this.timerStatus,
    this.sessionStartedAt,
    this.lastUpdatedAt,
    this.currentSessionElapsedSeconds,
    this.todayTotalSeconds,
    this.dailyDurationsMap,
    this.allTimeTotalSeconds,
  });

  final String? timerStatus; // "running", "paused", "resume", "end"

  @JsonKey(
    name: 'startAt',
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? sessionStartedAt;

  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? lastUpdatedAt;

  final int? currentSessionElapsedSeconds; // 현재 세션의 누적 시간 (초)

  final int? todayTotalSeconds; // 오늘의 총 활동 시간 (초)

  final Map<String, int>? dailyDurationsMap; // 일자별 활동 시간 {"2025-05-23": 3600}

  final int? allTimeTotalSeconds; // 전체 기간 총 누적 시간 (초)

  factory ActivityDto.fromJson(Map<String, dynamic> json) =>
      _$ActivityDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityDtoToJson(this);

  // copyWith 메서드
  ActivityDto copyWith({
    String? timerStatus,
    DateTime? sessionStartedAt,
    DateTime? lastUpdatedAt,
    int? currentSessionElapsedSeconds,
    int? todayTotalSeconds,
    Map<String, int>? dailyDurationsMap,
    int? allTimeTotalSeconds,
  }) {
    return ActivityDto(
      timerStatus: timerStatus ?? this.timerStatus,
      sessionStartedAt: sessionStartedAt ?? this.sessionStartedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      currentSessionElapsedSeconds:
          currentSessionElapsedSeconds ?? this.currentSessionElapsedSeconds,
      todayTotalSeconds: todayTotalSeconds ?? this.todayTotalSeconds,
      dailyDurationsMap: dailyDurationsMap ?? this.dailyDurationsMap,
      allTimeTotalSeconds: allTimeTotalSeconds ?? this.allTimeTotalSeconds,
    );
  }
}
