// lib/community/domain/model/post.dart
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
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLikedByCurrentUser = false,
    this.isBookmarkedByCurrentUser = false,
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
  final int likeCount;
  final int commentCount;
  final bool isLikedByCurrentUser;
  final bool isBookmarkedByCurrentUser;
}
