import 'package:devlink_mobile_app/community/data/dto/hash_tag_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/member_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class GroupDto {
  const GroupDto({
    this.id,
    this.name,
    this.description,
    this.members,
    this.hashTags,
    this.limitMemberCount,
    this.owner,
    this.imageUrl,
  });

  final String? id;
  final String? name;
  final String? description;
  final List<MemberDto>? members;
  final List<HashTagDto>? hashTags;

  final num? limitMemberCount;
  final MemberDto? owner;
  final String? imageUrl;

  factory GroupDto.fromJson(Map<String, dynamic> json) =>
      _$GroupDtoFromJson(json);
  Map<String, dynamic> toJson() => _$GroupDtoToJson(this);
}
