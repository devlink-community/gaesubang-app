// lib/auth/data/dto/summary_dto.dart
import 'package:devlink_mobile_app/core/utils/firebase_timestamp_converter.dart'; // 추가: 타임스탬프 변환기
import 'package:json_annotation/json_annotation.dart';

part 'summary_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class SummaryDto {
  const SummaryDto({
    this.allTimeTotalSeconds,
    this.groupTotalSecondsMap,
    this.last7DaysActivityMap,
    this.currentStreakDays,
    this.lastActivityDate,
    this.longestStreakDays,
    this.lastTimerState, // 추가: 마지막 타이머 상태 (문자열)
    this.lastTimerGroupId, // 추가: 마지막 타이머 그룹 ID
    this.lastTimerTimestamp, // 추가: 마지막 타이머 활동 시간
  });

  final int? allTimeTotalSeconds; // 전체 활동 시간 (초)

  final Map<String, int>? groupTotalSecondsMap; // 그룹별 누적 시간 {"groupA": 234000}

  final Map<String, int>? last7DaysActivityMap; // 최근 7일 활동 {"2025-05-23": 4500}

  final int? currentStreakDays; // 현재 연속 활동 일수

  final String? lastActivityDate; // 마지막 활동 날짜 "2025-05-23"

  final int? longestStreakDays; // 최장 연속 활동 일수

  final String?
  lastTimerState; // 추가: 마지막 타이머 상태 (문자열로 저장: "start", "pause", "resume", "end")

  final String? lastTimerGroupId; // 추가: 마지막 타이머 그룹 ID

  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? lastTimerTimestamp; // 추가: 마지막 타이머 활동 시간

  factory SummaryDto.fromJson(Map<String, dynamic> json) =>
      _$SummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SummaryDtoToJson(this);

  // copyWith 메서드
  SummaryDto copyWith({
    int? allTimeTotalSeconds,
    Map<String, int>? groupTotalSecondsMap,
    Map<String, int>? last7DaysActivityMap,
    int? currentStreakDays,
    String? lastActivityDate,
    int? longestStreakDays,
    String? lastTimerState, // 추가
    String? lastTimerGroupId, // 추가
    DateTime? lastTimerTimestamp, // 추가
  }) {
    return SummaryDto(
      allTimeTotalSeconds: allTimeTotalSeconds ?? this.allTimeTotalSeconds,
      groupTotalSecondsMap: groupTotalSecondsMap ?? this.groupTotalSecondsMap,
      last7DaysActivityMap: last7DaysActivityMap ?? this.last7DaysActivityMap,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      longestStreakDays: longestStreakDays ?? this.longestStreakDays,
      lastTimerState: lastTimerState ?? this.lastTimerState, // 추가
      lastTimerGroupId: lastTimerGroupId ?? this.lastTimerGroupId, // 추가
      lastTimerTimestamp: lastTimerTimestamp ?? this.lastTimerTimestamp, // 추가
    );
  }
}
