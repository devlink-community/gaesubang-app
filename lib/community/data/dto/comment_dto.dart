// lib/community/data/dto/comment_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'comment_dto.freezed.dart';
part 'comment_dto.g.dart';
@freezed
abstract class CommentDto with _$CommentDto {
  const factory CommentDto({
    String?   boardId,
    String?   memberId,
    DateTime? createdAt,
    String?   content,
  }) = _CommentDto;

  factory CommentDto.fromJson(Map<String, dynamic> json) =>
      _$CommentDtoFromJson(json);
}
