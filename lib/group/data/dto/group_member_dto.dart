// lib/group/data/dto/group_member_dto.dart
import 'package:devlink_mobile_app/core/utils/firebase_timestamp_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_member_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class GroupMemberDto {
  const GroupMemberDto({
    this.id,
    this.userId,
    this.userName,
    this.profileUrl,
    this.role,
    this.joinedAt,
    // 타이머 상태 필드 (통합)
    this.timerState,
    this.timerStartAt,
    this.timerLastUpdatedAt,
    this.timerElapsed,
    this.timerTodayDuration,
    this.timerMonthlyDurations,
    this.timerTotalDuration,
    this.timerPauseExpiryTime,
  });

  final String? id;
  final String? userId;
  final String? userName;
  final String? profileUrl;
  final String? role; // "owner", "member"

  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? joinedAt;

  // 타이머 상태 필드 추가 - Firebase에는 String으로 저장됨
  final String? timerState; // "running", "paused", "resume", "end"

  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? timerStartAt;

  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? timerLastUpdatedAt;

  final int? timerElapsed;
  final int? timerTodayDuration;
  final Map<String, int>? timerMonthlyDurations;
  final int? timerTotalDuration;

  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? timerPauseExpiryTime;

  factory GroupMemberDto.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberDtoFromJson(json);
  Map<String, dynamic> toJson() => _$GroupMemberDtoToJson(this);

  GroupMemberDto copyWith({
    String? id,
    String? userId,
    String? userName,
    String? profileUrl,
    String? role,
    DateTime? joinedAt,
    String? timerState,
    DateTime? timerStartAt,
    DateTime? timerLastUpdatedAt,
    int? timerElapsed,
    int? timerTodayDuration,
    Map<String, int>? timerMonthlyDurations,
    int? timerTotalDuration,
    DateTime? timerPauseExpiryTime,
  }) {
    return GroupMemberDto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      profileUrl: profileUrl ?? this.profileUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      timerState: timerState ?? this.timerState,
      timerStartAt: timerStartAt ?? this.timerStartAt,
      timerLastUpdatedAt: timerLastUpdatedAt ?? this.timerLastUpdatedAt,
      timerElapsed: timerElapsed ?? this.timerElapsed,
      timerTodayDuration: timerTodayDuration ?? this.timerTodayDuration,
      timerMonthlyDurations:
          timerMonthlyDurations ?? this.timerMonthlyDurations,
      timerTotalDuration: timerTotalDuration ?? this.timerTotalDuration,
      timerPauseExpiryTime: timerPauseExpiryTime ?? this.timerPauseExpiryTime,
    );
  }
}
