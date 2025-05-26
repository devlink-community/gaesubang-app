// lib/community/data/mapper/post_mapper.dart
import 'package:devlink_mobile_app/community/data/dto/post_comment_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/post_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/post_like_dto.dart';
import 'package:devlink_mobile_app/community/domain/model/comment.dart';
import 'package:devlink_mobile_app/community/domain/model/like.dart';
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/module/util/board_type_enum.dart';

/// PostDto → Post 변환
extension PostDtoMapper on PostDto {
  Post toModel() {
    return Post(
      id: id ?? '',
      title: title ?? '',
      content: content ?? '',
      authorId: authorId ?? '',
      authorNickname: authorNickname ?? 'Unknown User',
      authorPosition: authorPosition ?? '',
      userProfileImageUrl: userProfileImage ?? '',
      boardType: BoardType.free, // 기본값
      createdAt: createdAt ?? TimeFormatter.nowInSeoul(),
      hashTags: hashTags ?? [],
      imageUrls: mediaUrls ?? [],
      likeCount: likeCount ?? 0,
      commentCount: commentCount ?? 0,
      isLikedByCurrentUser: isLikedByCurrentUser ?? false,
      isBookmarkedByCurrentUser: isBookmarkedByCurrentUser ?? false,
    );
  }
}

/// PostCommentDto → Comment 변환
extension PostCommentDtoMapper on PostCommentDto {
  Comment toModel() {
    return Comment(
      id: id ?? '',
      userId: userId ?? '',
      userName: userName ?? 'Unknown User',
      userProfileImage: userProfileImage ?? '',
      text: text ?? '',
      createdAt: createdAt ?? TimeFormatter.nowInSeoul(),
      likeCount: likeCount ?? 0,
      isLikedByCurrentUser: isLikedByCurrentUser ?? false,
    );
  }
}

/// PostLikeDto → Like 변환
extension PostLikeDtoMapper on PostLikeDto {
  Like toModel() {
    return Like(
      userId: userId ?? '',
      userName: userName ?? 'Unknown User',
      timestamp: timestamp ?? TimeFormatter.nowInSeoul(),
    );
  }
}

/// List 변환 확장
extension PostDtoListMapper on List<PostDto> {
  List<Post> toModelList() => map((dto) => dto.toModel()).toList();
}

extension PostCommentDtoListMapper on List<PostCommentDto> {
  List<Comment> toModelList() => map((dto) => dto.toModel()).toList();
}

extension PostLikeDtoListMapper on List<PostLikeDto> {
  List<Like> toModelList() => map((dto) => dto.toModel()).toList();
}

/// Firebase Document → DTO 변환
extension FirebasePostMapper on Map<String, dynamic> {
  PostDto toPostDto() => PostDto.fromJson(this);
  PostCommentDto toPostCommentDto() => PostCommentDto.fromJson(this);
  PostLikeDto toPostLikeDto() => PostLikeDto.fromJson(this);
}

/// Firebase Document List → DTO List 변환
extension FirebasePostListMapper on List<Map<String, dynamic>> {
  List<PostDto> toPostDtoList() =>
      map((json) => PostDto.fromJson(json)).toList();
  List<PostCommentDto> toPostCommentDtoList() =>
      map((json) => PostCommentDto.fromJson(json)).toList();
  List<PostLikeDto> toPostLikeDtoList() =>
      map((json) => PostLikeDto.fromJson(json)).toList();
}
