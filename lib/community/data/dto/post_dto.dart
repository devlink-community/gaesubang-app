import 'package:cloud_firestore/cloud_firestore.dart';
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
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? createdAt;
  final List<String>? hashTags;

  factory PostDto.fromJson(Map<String, dynamic> json) =>
      _$PostDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PostDtoToJson(this);
}

// Timestamp 변환 유틸리티 함수
DateTime? _timestampFromJson(dynamic value) {
  if (value == null) return null;

  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  return null;
}

dynamic _timestampToJson(DateTime? dateTime) {
  if (dateTime == null) return null;
  return Timestamp.fromDate(dateTime);
}
