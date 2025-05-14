// lib/community/data/dto/comment_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'comment_dto.freezed.dart';
part 'comment_dto.g.dart';

@freezed
abstract class CommentDto with _$CommentDto {
  const factory CommentDto({
    String? userId,
    String? userName,
    String? userProfileImage,
    String? text,
    DateTime? createdAt,
    int? likeCount,
  }) = _CommentDto;

  factory CommentDto.fromJson(Map<String, dynamic> json) =>
      _$CommentDtoFromJson(json);
}