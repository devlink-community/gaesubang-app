// lib/community/data/data_source/post_data_source.dart
import 'package:devlink_mobile_app/community/data/dto/comment_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/post_dto.dart';

abstract interface class PostDataSource {
  /* List */
  Future<List<PostDto>> fetchPostList();

  /* Detail */
  Future<PostDto> fetchPostDetail(String postId);

  /* Toggle */
  Future<PostDto> toggleLike(String postId);
  Future<PostDto> toggleBookmark(String postId);

  /* Comment */
  Future<List<CommentDto>> fetchComments(String postId);
  Future<List<CommentDto>> addComment({
    required String postId,
    required String memberId,
    required String content,
  });
}
