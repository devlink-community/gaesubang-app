import 'package:json_annotation/json_annotation.dart';

part 'joined_group_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class JoinedGroupDto {
  const JoinedGroupDto({this.groupName, this.groupImage});

  @JsonKey(name: 'group_name')
  final String? groupName;
  @JsonKey(name: 'group_image')
  final String? groupImage;

  factory JoinedGroupDto.fromJson(Map<String, dynamic> json) =>
      _$JoinedGroupDtoFromJson(json);
  Map<String, dynamic> toJson() => _$JoinedGroupDtoToJson(this);
}
