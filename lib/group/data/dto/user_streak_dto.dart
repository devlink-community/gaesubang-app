// lib/group/data/dto/user_streak_dto.dart
import 'package:devlink_mobile_app/core/utils/firebase_timestamp_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_streak_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class UserStreakDto {
  const UserStreakDto({
    this.maxStreakDays,
    this.bestGroupId,
    this.bestGroupName,
    this.lastActiveDate,
  });

  final int? maxStreakDays;
  final String? bestGroupId;
  final String? bestGroupName;

  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? lastActiveDate;

  factory UserStreakDto.fromJson(Map<String, dynamic> json) =>
      _$UserStreakDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserStreakDtoToJson(this);

  // 필드 업데이트를 위한 copyWith 메서드
  UserStreakDto copyWith({
    int? maxStreakDays,
    String? bestGroupId,
    String? bestGroupName,
    DateTime? lastActiveDate,
  }) {
    return UserStreakDto(
      maxStreakDays: maxStreakDays ?? this.maxStreakDays,
      bestGroupId: bestGroupId ?? this.bestGroupId,
      bestGroupName: bestGroupName ?? this.bestGroupName,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }
}
