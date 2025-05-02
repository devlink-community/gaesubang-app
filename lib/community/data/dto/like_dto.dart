// lib/community/data/dto/like_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'like_dto.freezed.dart';
part 'like_dto.g.dart';

@freezed
abstract class LikeDto with _$LikeDto {
  const factory LikeDto({
    String? boardId,
    String? memberId,
  }) = _LikeDto;

  factory LikeDto.fromJson(Map<String, dynamic> json) =>
      _$LikeDtoFromJson(json);
}
