// lib/auth/data/dto/user_dto.dart
import 'package:json_annotation/json_annotation.dart';

import '../../../core/utils/firebase_timestamp_converter.dart';
import 'joined_group_dto.dart';

part 'user_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class UserDto {
  const UserDto({
    this.email,
    this.nickname,
    this.uid,
    this.image,
    this.agreedTermId,
    this.description,
    this.isServiceTermsAgreed,
    this.isPrivacyPolicyAgreed,
    this.isMarketingAgreed,
    this.agreedAt,
    this.joinedGroups,
    this.position,
    this.skills,
    // 🚀 통계 필드들
    this.onAir,
    this.streakDays,
    this.totalFocusMinutes,
    this.weeklyFocusMinutes,
    this.lastStatsUpdated,
    this.dailyFocusMinutes, // 🆕 일별 데이터 추가
  });

  final String? email;
  final String? nickname;
  final String? uid;
  final String? image;
  final String? agreedTermId;
  final String? description;
  final bool? isServiceTermsAgreed;
  final bool? isPrivacyPolicyAgreed;
  final bool? isMarketingAgreed;
  final String? position;
  final String? skills;

  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? agreedAt;

  @JsonKey(name: 'joingroup')
  final List<JoinedGroupDto>? joinedGroups;

  // 🚀 통계 필드들
  final bool? onAir;
  final int? streakDays;
  final int? totalFocusMinutes;
  final int? weeklyFocusMinutes;

  // 🆕 일별 집중 시간 데이터 추가
  final Map<String, int>? dailyFocusMinutes;

  @JsonKey(name: 'lastStatsUpdated')
  final String? lastStatsUpdated; // ISO 8601 문자열로 저장

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}
