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
    this.ownerId,
    this.ownerNickname,
    this.ownerProfileImage,
    this.maxMemberCount,
    this.hashTags,
    this.memberCount,
    this.isJoinedByCurrentUser = false,
    this.pauseTimeLimit = 120, // 기본값 120분
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

  @JsonKey(name: 'createdBy')
  final String? ownerId;
  final String? ownerNickname;
  final String? ownerProfileImage;

  final int? maxMemberCount;
  final List<String>? hashTags;
  final int? memberCount;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool? isJoinedByCurrentUser;

  final int? pauseTimeLimit; // 일시정지 제한시간 (분 단위)

  factory GroupDto.fromJson(Map<String, dynamic> json) =>
      _$GroupDtoFromJson(json);
  Map<String, dynamic> toJson() => _$GroupDtoToJson(this);

  GroupDto copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    DateTime? createdAt,
    String? ownerId,
    String? ownerNickname,
    String? ownerProfileImage,
    int? maxMemberCount,
    List<String>? hashTags,
    int? memberCount,
    bool? isJoinedByCurrentUser,
    int? pauseTimeLimit,
  }) {
    return GroupDto(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      ownerId: ownerId ?? this.ownerId,
      ownerNickname: ownerNickname ?? this.ownerNickname,
      ownerProfileImage: ownerProfileImage ?? this.ownerProfileImage,
      maxMemberCount: maxMemberCount ?? this.maxMemberCount,
      hashTags: hashTags ?? this.hashTags,
      memberCount: memberCount ?? this.memberCount,
      isJoinedByCurrentUser:
          isJoinedByCurrentUser ?? this.isJoinedByCurrentUser,
      pauseTimeLimit: pauseTimeLimit ?? this.pauseTimeLimit,
    );
  }
}
