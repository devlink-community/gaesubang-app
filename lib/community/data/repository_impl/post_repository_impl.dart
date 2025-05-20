// lib/community/data/repository_impl/post_repository_impl.dart
import 'package:devlink_mobile_app/community/data/data_source/post_data_source.dart';
import 'package:devlink_mobile_app/community/data/mapper/post_mapper.dart';
import 'package:devlink_mobile_app/community/domain/model/comment.dart';
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';
import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/exception_mappers/auth_exception_mapper.dart';
import 'package:devlink_mobile_app/core/utils/messages/community_error_messages.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PostRepositoryImpl implements PostRepository {
  const PostRepositoryImpl({
    required PostDataSource dataSource,
    required Ref ref,
  }) : _dataSource = dataSource,
       _ref = ref;

  final PostDataSource _dataSource;
  final Ref _ref;

  /* ---------- List ---------- */
  @override
  Future<Result<List<Post>>> loadPostList() async {
    return ApiCallDecorator.wrap('PostRepository.loadPostList', () async {
      try {
        final postDtos = await _dataSource.fetchPostList();
        final posts = postDtos.toModelList();
        return Result.success(posts);
      } catch (e, st) {
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    });
  }

  /* ---------- Detail ---------- */
  @override
  Future<Result<Post>> getPostDetail(String id) async {
    return ApiCallDecorator.wrap('PostRepository.getPostDetail', () async {
      try {
        final postDto = await _dataSource.fetchPostDetail(id);
        final post = postDto.toModel();
        return Result.success(post);
      } catch (e, st) {
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'postId': id});
  }

  /* ---------- Toggle ---------- */
  @override
  Future<Result<Post>> toggleLike(String id) async {
    return ApiCallDecorator.wrap('PostRepository.toggleLike', () async {
      try {
        // Auth에서 현재 사용자 정보 가져오기
        final currentUser = _ref.read(currentUserProvider);
        if (currentUser == null) {
          throw Exception(CommunityErrorMessages.loginRequired);
        }

        final postDto = await _dataSource.toggleLike(
          id,
          currentUser.uid,
          currentUser.nickname,
        );
        final post = postDto.toModel();
        return Result.success(post);
      } catch (e, st) {
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'postId': id});
  }

  @override
  Future<Result<Post>> toggleBookmark(String id) async {
    return ApiCallDecorator.wrap('PostRepository.toggleBookmark', () async {
      try {
        // Auth에서 현재 사용자 정보 가져오기
        final currentUser = _ref.read(currentUserProvider);
        if (currentUser == null) {
          throw Exception(CommunityErrorMessages.loginRequired);
        }

        final postDto = await _dataSource.toggleBookmark(id, currentUser.uid);
        final post = postDto.toModel();
        return Result.success(post);
      } catch (e, st) {
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'postId': id});
  }

  /* ---------- Comment ---------- */
  @override
  Future<Result<List<Comment>>> getComments(String id) async {
    return ApiCallDecorator.wrap('PostRepository.getComments', () async {
      try {
        final commentDtos = await _dataSource.fetchComments(id);
        final comments = commentDtos.toModelList();
        return Result.success(comments);
      } catch (e, st) {
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'postId': id});
  }

  @override
  Future<Result<List<Comment>>> createComment({
    required String postId,
    required String memberId,
    required String content,
  }) async {
    return ApiCallDecorator.wrap('PostRepository.createComment', () async {
      try {
        // Auth에서 현재 사용자 정보 가져오기
        final currentUser = _ref.read(currentUserProvider);
        if (currentUser == null) {
          throw Exception(CommunityErrorMessages.loginRequired);
        }

        final commentDtos = await _dataSource.createComment(
          postId: postId,
          userId: currentUser.uid,
          userName: currentUser.nickname,
          userProfileImage: currentUser.image,
          content: content,
        );
        final comments = commentDtos.toModelList();
        return Result.success(comments);
      } catch (e, st) {
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'postId': postId});
  }

  /* ---------- Search ---------- */
  @override
  Future<Result<List<Post>>> searchPosts(String query) async {
    return ApiCallDecorator.wrap('PostRepository.searchPosts', () async {
      try {
        final postDtos = await _dataSource.searchPosts(query);
        final posts = postDtos.toModelList();
        return Result.success(posts);
      } catch (e, st) {
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'query': query});
  }

  /* ---------- Create ---------- */
  @override
  Future<String> createPost({
    required String postId,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  }) async {
    return ApiCallDecorator.wrap('PostRepository.createPost', () async {
      try {
        // Auth에서 현재 사용자 정보 가져오기
        final currentUser = _ref.read(currentUserProvider);
        if (currentUser == null) {
          throw Exception(CommunityErrorMessages.loginRequired);
        }

        // 현재 사용자의 프로필 정보 가져오기 (닉네임, 직책/포지션)
        final createdPostId = await _dataSource.createPost(
          postId: postId,
          authorId: currentUser.uid,
          authorNickname: currentUser.nickname,
          authorPosition: currentUser.position ?? '',
          userProfileImage: currentUser.image,
          title: title,
          content: content,
          hashTags: hashTags,
          imageUris: imageUris,
        );

        return createdPostId;
      } catch (e, st) {
        // createPost는 String 반환이므로 예외를 다시 던짐
        throw Exception(CommunityErrorMessages.postCreateFailed);
      }
    }, params: {'postId': postId});
  }

  @override
  Future<Result<Comment>> toggleCommentLike(
    String postId,
    String commentId,
  ) async {
    return ApiCallDecorator.wrap(
      'PostRepository.toggleCommentLike',
      () async {
        try {
          // Auth에서 현재 사용자 정보 가져오기
          final currentUser = _ref.read(currentUserProvider);
          if (currentUser == null) {
            throw Exception(CommunityErrorMessages.loginRequired);
          }

          final commentDto = await _dataSource.toggleCommentLike(
            postId,
            commentId,
            currentUser.uid,
            currentUser.nickname,
          );
          final comment = commentDto.toModel();
          return Result.success(comment);
        } catch (e, st) {
          return Result.error(AuthExceptionMapper.mapAuthException(e, st));
        }
      },
      params: {'postId': postId, 'commentId': commentId},
    );
  }

  @override
  Future<Result<Map<String, bool>>> checkCommentsLikeStatus(
    String postId,
    List<String> commentIds,
  ) async {
    return ApiCallDecorator.wrap(
      'PostRepository.checkCommentsLikeStatus',
      () async {
        try {
          // Auth에서 현재 사용자 정보 가져오기
          final currentUser = _ref.read(currentUserProvider);
          if (currentUser == null) {
            // 로그인하지 않은 경우 모든 댓글의 좋아요 상태를 false로 반환
            return Result.success({
              for (final commentId in commentIds) commentId: false,
            });
          }

          final result = await _dataSource.checkCommentsLikeStatus(
            postId,
            commentIds,
            currentUser.uid,
          );
          return Result.success(result);
        } catch (e, st) {
          return Result.error(AuthExceptionMapper.mapAuthException(e, st));
        }
      },
      params: {'postId': postId, 'commentCount': commentIds.length},
    );
  }
}
