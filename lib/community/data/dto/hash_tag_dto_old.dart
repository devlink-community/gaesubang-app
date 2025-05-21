// lib/community/data/dto/hash_tag_dto_old.dart
import 'package:json_annotation/json_annotation.dart';

part 'hash_tag_dto_old.g.dart';

@JsonSerializable()
class HashTagDto {
  const HashTagDto({this.id, this.content});

  final String? id;
  final String? content;

  factory HashTagDto.fromJson(Map<String, dynamic> json) =>
      _$HashTagDtoFromJson(json);
  Map<String, dynamic> toJson() => _$HashTagDtoToJson(this);
}
