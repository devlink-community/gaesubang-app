// lib/community/data/data_source/post_data_source.dart
import 'package:devlink_mobile_app/community/data/dto/post_comment_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/post_dto.dart';

abstract interface class PostDataSource {
  /* List */
  Future<List<PostDto>> fetchPostList({String? currentUserId});

  /* Detail */
  Future<PostDto> fetchPostDetail(String postId, {String? currentUserId});

  /* Toggle - 사용자 정보 파라미터 추가 */
  Future<PostDto> toggleLike(String postId, String userId, String userName);
  Future<PostDto> toggleBookmark(String postId, String userId);

  /* Comment - 사용자 정보 파라미터 추가 */
  Future<List<PostCommentDto>> fetchComments(
    String postId, {
    String? currentUserId,
  });
  Future<List<PostCommentDto>> createComment({
    required String postId,
    required String userId,
    required String userName,
    required String userProfileImage,
    required String content,
  });

  /* Comment Like - 기존 메서드 */
  Future<PostCommentDto> toggleCommentLike(
    String postId,
    String commentId,
    String userId,
    String userName,
  );

  /* 상태 일괄 조회 메서드 - 새로 추가 */
  // 좋아요 상태 일괄 조회 - N+1 문제 해결
  Future<Map<String, bool>> checkUserLikeStatus(
    List<String> postIds,
    String userId,
  );

  // 북마크 상태 일괄 조회 - N+1 문제 해결
  Future<Map<String, bool>> checkUserBookmarkStatus(
    List<String> postIds,
    String userId,
  );

  // 댓글 좋아요 상태 일괄 조회 - 기존 메서드
  Future<Map<String, bool>> checkCommentsLikeStatus(
    String postId,
    List<String> commentIds,
    String userId,
  );

  /* Search */
  Future<List<PostDto>> searchPosts(String query, {String? currentUserId});

  /* Create - 작성자 정보 파라미터 업데이트 */
  Future<String> createPost({
    required String postId,
    required String authorId,
    required String authorNickname, // 추가: 작성자 닉네임
    required String authorPosition, // 추가: 작성자 직책/포지션
    required String userProfileImage,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  });

  /* Update */
  Future<String> updatePost({
    required String postId,
    required String authorId, // 권한 확인용
    required String authorNickname,
    required String authorPosition,
    required String userProfileImage,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  });

  /* Delete */
  Future<bool> deletePost(String postId, String userId);
}
