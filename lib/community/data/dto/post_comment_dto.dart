import 'package:json_annotation/json_annotation.dart';

import '../../../core/utils/firebase_timestamp_converter.dart';

part 'post_comment_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class PostCommentDto {
  const PostCommentDto({
    this.id,
    this.userId,
    this.userName,
    this.userProfileImage,
    this.text,
    this.createdAt,
    this.likeCount,
  });

  final String? id;
  final String? userId;
  final String? userName;
  final String? userProfileImage;
  final String? text;
  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? createdAt;
  final int? likeCount;

  factory PostCommentDto.fromJson(Map<String, dynamic> json) =>
      _$PostCommentDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PostCommentDtoToJson(this);
}
