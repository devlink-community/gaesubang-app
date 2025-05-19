import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_member_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class GroupMemberDto {
  const GroupMemberDto({
    this.userId,
    this.userName,
    this.profileUrl,
    this.role,
    this.joinedAt,
    this.isActive,
  });

  final String? userId;
  final String? userName;
  final String? profileUrl;
  final String? role; // "admin", "moderator", "member"
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? joinedAt;
  final bool? isActive;

  factory GroupMemberDto.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberDtoFromJson(json);
  Map<String, dynamic> toJson() => _$GroupMemberDtoToJson(this);
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
