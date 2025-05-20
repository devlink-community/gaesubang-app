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
    this.isLikedByCurrentUser = false, // 추가된 필드
    this.isBookmarkedByCurrentUser = false, // 추가된 필드
  });

  final String? id;
  final String? authorId;
  final String? authorNickname; // 추가: 작성자 닉네임
  final String? authorPosition; // 추가: 작성자 직책/포지션
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

  @JsonKey(includeFromJson: false, includeToJson: false) // Firebase에 저장하지 않음
  final int? likeCount; // 서브컬렉션 쿼리로 계산

  @JsonKey(includeFromJson: false, includeToJson: false) // Firebase에 저장하지 않음
  final bool? isLikedByCurrentUser; // 현재 사용자의 좋아요 상태

  @JsonKey(includeFromJson: false, includeToJson: false) // Firebase에 저장하지 않음
  final bool? isBookmarkedByCurrentUser; // 현재 사용자의 북마크 상태

  factory PostDto.fromJson(Map<String, dynamic> json) =>
      _$PostDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PostDtoToJson(this);

  // 필드 업데이트를 위한 copyWith 메서드 추가
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
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      isBookmarkedByCurrentUser:
          isBookmarkedByCurrentUser ?? this.isBookmarkedByCurrentUser,
    );
  }
}
