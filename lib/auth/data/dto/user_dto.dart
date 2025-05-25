// lib/auth/data/dto/user_dto.dart
import 'package:json_annotation/json_annotation.dart';

import '../../../core/utils/firebase_timestamp_converter.dart';
import 'joined_group_dto.dart';
import 'summary_dto.dart';

part 'user_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class UserDto {
  const UserDto({
    this.email,
    this.nickname,
    this.uid,
    this.image,
    this.description,
    this.isServiceTermsAgreed,
    this.isPrivacyPolicyAgreed,
    this.isMarketingAgreed,
    this.agreedAt,
    this.joinedGroups,
    this.position,
    this.skills,
    this.onAir,
    this.streakDays,
    this.userSummary,
  });

  final String? email;
  final String? nickname;
  final String? uid;
  final String? image;
  final String? description;
  final bool? isServiceTermsAgreed;
  final bool? isPrivacyPolicyAgreed;
  final bool? isMarketingAgreed;
  final String? position;
  final String? skills;
  final bool? onAir;
  final int? streakDays;

  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? agreedAt;

  @JsonKey(name: 'joingroup')
  final List<JoinedGroupDto>? joinedGroups;

  @JsonKey(name: 'summary')
  final SummaryDto? userSummary;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);

  // copyWith 메서드 업데이트
  UserDto copyWith({
    String? email,
    String? nickname,
    String? uid,
    String? image,
    String? description,
    bool? isServiceTermsAgreed,
    bool? isPrivacyPolicyAgreed,
    bool? isMarketingAgreed,
    DateTime? agreedAt,
    List<JoinedGroupDto>? joinedGroups,
    String? position,
    String? skills,
    SummaryDto? userSummary,
  }) {
    return UserDto(
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      uid: uid ?? this.uid,
      image: image ?? this.image,
      description: description ?? this.description,
      isServiceTermsAgreed: isServiceTermsAgreed ?? this.isServiceTermsAgreed,
      isPrivacyPolicyAgreed:
          isPrivacyPolicyAgreed ?? this.isPrivacyPolicyAgreed,
      isMarketingAgreed: isMarketingAgreed ?? this.isMarketingAgreed,
      agreedAt: agreedAt ?? this.agreedAt,
      joinedGroups: joinedGroups ?? this.joinedGroups,
      position: position ?? this.position,
      skills: skills ?? this.skills,
      userSummary: userSummary ?? this.userSummary,
    );
  }
}
