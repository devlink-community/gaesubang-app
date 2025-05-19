import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/firebase_timestamp_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'post_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class PostDto {
  const PostDto({
    this.id,
    this.authorId,
    this.userProfileImage,
    this.title,
    this.content,
    this.mediaUrls,
    this.createdAt,
    this.hashTags,
  });

  final String? id;
  final String? authorId;
  final String? userProfileImage;
  final String? title;
  final String? content;
  final List<String>? mediaUrls;
  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? createdAt;
  final List<String>? hashTags;

  factory PostDto.fromJson(Map<String, dynamic> json) =>
      _$PostDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PostDtoToJson(this);
}
