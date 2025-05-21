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

  factory GroupMemberDto.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberDtoFromJson(json);
  Map<String, dynamic> toJson() => _$GroupMemberDtoToJson(this);

  // 필드 업데이트를 위한 copyWith 메서드
  GroupMemberDto copyWith({
    String? id,
    String? userId,
    String? userName,
    String? profileUrl,
    String? role,
    DateTime? joinedAt,
  }) {
    return GroupMemberDto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      profileUrl: profileUrl ?? this.profileUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
