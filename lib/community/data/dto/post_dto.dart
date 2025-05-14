// lib/community/data/dto/post_dto.dart
import 'package:devlink_mobile_app/community/data/dto/comment_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/like_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/member_dto.dart';
import 'package:devlink_mobile_app/community/module/util/board_type_enum.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_dto.freezed.dart';
part 'post_dto.g.dart';

/// 게시글 DTO (모든 필드 nullable)
@freezed
abstract class PostDto with _$PostDto {
  const factory PostDto({
    String? id,
    String? title,
    String? content,
    MemberDto? member,
    String? userProfileImage,
    BoardType? boardType,
    DateTime? createdAt,
    List<String>? hashTags,
    List<String>? mediaUrls,
    List<LikeDto>? like,
    List<CommentDto>? comment,
  }) = _PostDto;

  factory PostDto.fromJson(Map<String, dynamic> json) =>
      _$PostDtoFromJson(json);
}