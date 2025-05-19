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
    this.isActive,
  });

  final String? id;
  final String? userId;
  final String? userName;
  final String? profileUrl;
  final String? role; // "admin", "moderator", "member"
  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? joinedAt;
  final bool? isActive;

  factory GroupMemberDto.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberDtoFromJson(json);
  Map<String, dynamic> toJson() => _$GroupMemberDtoToJson(this);
}
