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
  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? agreedAt;
  @JsonKey(name: 'joingroup')
  final List<JoinedGroupDto>? joinedGroups;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}
