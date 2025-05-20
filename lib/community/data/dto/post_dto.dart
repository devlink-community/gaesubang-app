// lib/community/data/dto/post_dto.dart
import 'package:devlink_mobile_app/core/utils/firebase_timestamp_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'post_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class PostDto {
  const PostDto({
    this.id,
    this.authorId,
    this.authorNickname,
    this.authorPosition,
    this.userProfileImage,
    this.title,
    this.content,
    this.mediaUrls,
    this.createdAt,
    this.hashTags,
    this.likeCount,
    this.commentCount,
    this.isLikedByCurrentUser = false,
    this.isBookmarkedByCurrentUser = false,
  });

  final String? id;
  final String? authorId;
  final String? authorNickname;
  final String? authorPosition;
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

  // 비정규화된 카운터 - 실제 Firestore에 저장됨
  final int? likeCount;
  final int? commentCount;

  // UI 전용 필드 - Firestore에는 저장하지 않음
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool? isLikedByCurrentUser;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool? isBookmarkedByCurrentUser;

  factory PostDto.fromJson(Map<String, dynamic> json) =>
      _$PostDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PostDtoToJson(this);

  // 필드 업데이트를 위한 copyWith 메서드
  PostDto copyWith({
    String? id,
    String? authorId,
    String? authorNickname,
    String? authorPosition,
    String? userProfileImage,
    String? title,
    String? content,
    List<String>? mediaUrls,
    DateTime? createdAt,
    List<String>? hashTags,
    int? likeCount,
    int? commentCount,
    bool? isLikedByCurrentUser,
    bool? isBookmarkedByCurrentUser,
  }) {
    return PostDto(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorNickname: authorNickname ?? this.authorNickname,
      authorPosition: authorPosition ?? this.authorPosition,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      title: title ?? this.title,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      createdAt: createdAt ?? this.createdAt,
      hashTags: hashTags ?? this.hashTags,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      isBookmarkedByCurrentUser:
          isBookmarkedByCurrentUser ?? this.isBookmarkedByCurrentUser,
    );
  }
}
