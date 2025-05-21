// lib/community/data/dto/post_comment_dto.dart
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
    this.isLikedByCurrentUser = false,
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

  // 비정규화된 카운터 - Firestore에 저장
  final int? likeCount;

  // UI 전용 필드 - Firestore에는 저장하지 않음
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool? isLikedByCurrentUser;

  factory PostCommentDto.fromJson(Map<String, dynamic> json) =>
      _$PostCommentDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PostCommentDtoToJson(this);

  // 필드 업데이트를 위한 copyWith 메서드
  PostCommentDto copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfileImage,
    String? text,
    DateTime? createdAt,
    int? likeCount,
    bool? isLikedByCurrentUser,
  }) {
    return PostCommentDto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
    );
  }
}
