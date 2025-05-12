// lib/community/data/dto/hash_tag_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'hash_tag_dto.freezed.dart';
part 'hash_tag_dto.g.dart';

@freezed
abstract class HashTagDto with _$HashTagDto {
  const factory HashTagDto({
    String? id,
    String? content,
  }) = _HashTagDto;

  factory HashTagDto.fromJson(Map<String, dynamic> json) =>
      _$HashTagDtoFromJson(json);
}
