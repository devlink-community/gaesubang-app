import 'package:devlink_mobile_app/core/utils/firebase_timestamp_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class GroupDto {
  const GroupDto({
    this.name,
    this.description,
    this.imageUrl,
    this.createdAt,
    this.createdBy,
    this.maxMemberCount,
    this.hashTags,
  });

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

  factory GroupDto.fromJson(Map<String, dynamic> json) =>
      _$GroupDtoFromJson(json);
  Map<String, dynamic> toJson() => _$GroupDtoToJson(this);
}
