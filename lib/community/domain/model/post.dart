// lib/community/domain/model/post.dart
import 'package:devlink_mobile_app/community/domain/model/comment.dart';
import 'package:devlink_mobile_app/community/domain/model/like.dart';
import 'package:devlink_mobile_app/community/module/util/board_type_enum.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';

@freezed
class Post with _$Post {
  const Post({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorNickname,
    required this.authorPosition,
    required this.userProfileImageUrl,
    required this.boardType,
    required this.createdAt,
    this.hashTags = const <String>[],
    this.imageUrls = const <String>[],
    this.like = const <Like>[],
    this.comment = const <Comment>[],
    this.isLikedByCurrentUser = false, // 추가된 필드
    this.isBookmarkedByCurrentUser = false, // 추가된 필드
  });

  final String id;
  final String title;
  final String content;

  // 작성자 정보 (Member 객체 대신 개별 필드)
  final String authorId;
  final String authorNickname;
  final String authorPosition;
  final String userProfileImageUrl;

  final BoardType boardType;
  final DateTime createdAt;
  final List<String> hashTags;
  final List<String> imageUrls;
  final List<Like> like;
  final List<Comment> comment;
  final bool isLikedByCurrentUser; // 추가된 필드
  final bool isBookmarkedByCurrentUser; // 추가된 필드
}
