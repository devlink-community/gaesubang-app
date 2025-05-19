import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/firebase_timestamp_converter.dart';
import 'package:json_annotation/json_annotation.dart';

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
    this.joingroup,
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
  final List<Map<String, dynamic>>? joingroup;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}
