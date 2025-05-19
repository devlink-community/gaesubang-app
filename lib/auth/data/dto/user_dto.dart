import 'package:cloud_firestore/cloud_firestore.dart';
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
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? agreedAt;
  final List<Map<String, dynamic>>? joingroup;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
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
