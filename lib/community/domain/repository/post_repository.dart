// lib/community/domain/repository/post_repository.dart
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/community/domain/model/comment.dart';
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/core/result/result.dart';

abstract interface class PostRepository {
  /* List */
  Future<Result<List<Post>>> loadPostList();

  /* Detail */
  Future<Result<Post>> getPostDetail(String postId);

  /* Toggle */
  Future<Result<Post>> toggleLike(String postId);
  Future<Result<Post>> toggleBookmark(String postId);

  /* Comment */
  Future<Result<List<Comment>>> getComments(String postId);
  Future<Result<List<Comment>>> createComment({
    required String postId,
    required String content,
  });

  /* Comment Like - 새로 추가된 메서드 */
  Future<Result<Comment>> toggleCommentLike(String postId, String commentId);
  Future<Result<Map<String, bool>>> checkCommentsLikeStatus(
    String postId,
    List<String> commentIds,
  );

  /* Search - 추가 */
  Future<Result<List<Post>>> searchPosts(String query);

  /* Create */
  Future<String> createPost({
    required String postId,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
    Member? author,
  });
}
