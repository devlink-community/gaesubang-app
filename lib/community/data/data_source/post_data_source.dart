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
  Future<List<CommentDto>> createComment({
    required String postId,
    required String memberId,
    required String content,
  });

  /* ---------- NEW : 게시글 작성 ---------- */
  Future<String> createPost({
    required String postId,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  });
}
