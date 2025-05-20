// lib/group/data/dto/group_dto.dart
import 'package:devlink_mobile_app/core/utils/firebase_timestamp_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class GroupDto {
  const GroupDto({
    this.id,
    this.name,
    this.description,
    this.imageUrl,
    this.createdAt,
    this.createdBy,
    this.maxMemberCount,
    this.hashTags,
    this.memberCount,
    this.isJoinedByCurrentUser = false,
  });

  final String? id;
  final String? name;
  final String? description;
  final String? imageUrl;
  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? createdAt;
  final String? createdBy;
  final int? maxMemberCount;
  final List<String>? hashTags;
  final int? memberCount;

  // UI 전용 필드 - Firestore에는 저장하지 않음
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool? isJoinedByCurrentUser;

  factory GroupDto.fromJson(Map<String, dynamic> json) =>
      _$GroupDtoFromJson(json);
  Map<String, dynamic> toJson() => _$GroupDtoToJson(this);

  // 필드 업데이트를 위한 copyWith 메서드
  GroupDto copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    DateTime? createdAt,
    String? createdBy,
    int? maxMemberCount,
    List<String>? hashTags,
    int? memberCount,
    bool? isJoinedByCurrentUser,
  }) {
    return GroupDto(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      maxMemberCount: maxMemberCount ?? this.maxMemberCount,
      hashTags: hashTags ?? this.hashTags,
      memberCount: memberCount ?? this.memberCount,
      isJoinedByCurrentUser:
          isJoinedByCurrentUser ?? this.isJoinedByCurrentUser,
    );
  }
}
