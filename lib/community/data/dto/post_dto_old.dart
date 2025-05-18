// lib/community/data/dto/post_dto_old.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/community/data/dto/comment_dto_old.dart';
import 'package:devlink_mobile_app/community/data/dto/like_dto_old.dart';
import 'package:devlink_mobile_app/community/data/dto/member_dto_old.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_dto_old.freezed.dart';
part 'post_dto_old.g.dart';

/// 게시글 DTO (모든 필드 nullable)
@freezed
abstract class PostDto with _$PostDto {
  const factory PostDto({
    String? id,
    String? title,
    String? content,
    MemberDto? member,
    String? userProfileImageUrl,
    dynamic boardType, // String 또는 BoardType enum 모두 처리 가능하도록
    @JsonKey(
      name: 'createAt',
      fromJson: _dateTimeFromJson,
      toJson: _dateTimeToJson,
    )
    DateTime? createdAt,
    List<String>? hashTags,
    List<String>? imageUrls,
    @JsonKey(name: 'like') List<LikeDto>? like,
    @JsonKey(name: 'comment') List<CommentDto>? comment,
  }) = _PostDto;

  factory PostDto.fromJson(Map<String, dynamic> json) =>
      _$PostDtoFromJson(json);
}

// DateTime JSON 변환 유틸리티 함수
DateTime? _dateTimeFromJson(dynamic value) {
  if (value == null) return null;

  if (value is String) {
    return DateTime.parse(value);
  }

  if (value is Timestamp) {
    return value.toDate();
  }

  return null;
}

dynamic _dateTimeToJson(DateTime? dateTime) {
  if (dateTime == null) return null;
  return Timestamp.fromDate(dateTime);
}
