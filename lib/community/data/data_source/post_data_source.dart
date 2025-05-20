// lib/community/data/data_source/post_data_source.dart
import 'package:devlink_mobile_app/community/data/dto/post_comment_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/post_dto.dart';

abstract interface class PostDataSource {
  /* List */
  Future<List<PostDto>> fetchPostList();

  /* Detail */
  Future<PostDto> fetchPostDetail(String postId);

  /* Toggle - 사용자 정보 파라미터 추가 */
  Future<PostDto> toggleLike(String postId, String userId, String userName);
  Future<PostDto> toggleBookmark(String postId, String userId);

  /* Comment - 사용자 정보 파라미터 추가 */
  Future<List<PostCommentDto>> fetchComments(String postId);
  Future<List<PostCommentDto>> createComment({
    required String postId,
    required String userId,
    required String userName,
    required String userProfileImage,
    required String content,
  });

  /* Search */
  Future<List<PostDto>> searchPosts(String query);

  /* Create - 사용자 정보 파라미터 추가 */
  Future<String> createPost({
    required String postId,
    required String authorId,
    required String userProfileImage,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  });
}
