// lib/community/data/data_source/post_data_source.dart
import 'package:devlink_mobile_app/community/data/dto/post_comment_dto.dart';
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
  Future<List<PostCommentDto>> fetchComments(String postId);
  Future<List<PostCommentDto>> createComment({
    required String postId,
    required String content,
  });

  /* Comment Like */
  Future<PostCommentDto> toggleCommentLike(String postId, String commentId);

  /* 상태 일괄 조회 메서드 - 내부에서 현재 사용자 처리 */
  Future<Map<String, bool>> checkUserLikeStatus(List<String> postIds);

  Future<Map<String, bool>> checkUserBookmarkStatus(List<String> postIds);

  Future<Map<String, bool>> checkCommentsLikeStatus(
    String postId,
    List<String> commentIds,
  );

  /* Search */
  Future<List<PostDto>> searchPosts(String query);

  /* Create */
  Future<String> createPost({
    required String postId,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  });

  /* Update */
  Future<String> updatePost({
    required String postId,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  });

  /* Delete */
  Future<bool> deletePost(String postId);
}
