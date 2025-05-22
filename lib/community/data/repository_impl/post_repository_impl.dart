// lib/community/data/repository_impl/post_repository_impl.dart
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/community/data/data_source/post_data_source.dart';
import 'package:devlink_mobile_app/community/data/mapper/post_mapper.dart';
import 'package:devlink_mobile_app/community/domain/model/comment.dart';
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/exception_mappers/auth_exception_mapper.dart';

class PostRepositoryImpl implements PostRepository {
  const PostRepositoryImpl({required PostDataSource dataSource})
    : _dataSource = dataSource;

  final PostDataSource _dataSource;

  /* ---------- List ---------- */
  @override
  Future<Result<List<Post>>> loadPostList() async {
    return ApiCallDecorator.wrap('PostRepository.loadPostList', () async {
      try {
        // DataSource에서 현재 사용자 정보 처리
        final postDtos = await _dataSource.fetchPostList();

        // DTO를 Model로 변환
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
        final postDto = await _dataSource.toggleLike(id);
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
        final postDto = await _dataSource.toggleBookmark(id);
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
    required String content,
  }) async {
    return ApiCallDecorator.wrap('PostRepository.createComment', () async {
      try {
        final commentDtos = await _dataSource.createComment(
          postId: postId,
          content: content,
        );
        final comments = commentDtos.toModelList();
        return Result.success(comments);
      } catch (e, st) {
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'postId': postId});
  }

  /* ---------- Comment Like ---------- */
  @override
  Future<Result<Comment>> toggleCommentLike(
    String postId,
    String commentId,
  ) async {
    return ApiCallDecorator.wrap(
      'PostRepository.toggleCommentLike',
      () async {
        try {
          final commentDto = await _dataSource.toggleCommentLike(
            postId,
            commentId,
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

  /* ---------- Search ---------- */
  @override
  Future<Result<List<Post>>> searchPosts(String query) async {
    return ApiCallDecorator.wrap('PostRepository.searchPosts', () async {
      try {
        final postDtos = await _dataSource.searchPosts(query);

        // DTO를 Model로 변환
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
    Member? author,
  }) async {
    return ApiCallDecorator.wrap('PostRepository.createPost', () async {
      try {
        // DataSource에서 현재 사용자 정보 처리
        final createdPostId = await _dataSource.createPost(
          postId: postId,
          title: title,
          content: content,
          hashTags: hashTags,
          imageUris: imageUris,
        );

        return createdPostId;
      } catch (e) {
        // createPost는 String 반환이므로 예외를 다시 던짐
        throw Exception('게시글 작성에 실패했습니다');
      }
    }, params: {'postId': postId});
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
          final result = await _dataSource.checkCommentsLikeStatus(
            postId,
            commentIds,
          );
          return Result.success(result);
        } catch (e, st) {
          return Result.error(AuthExceptionMapper.mapAuthException(e, st));
        }
      },
      params: {'postId': postId, 'commentCount': commentIds.length},
    );
  }

  /* Update */
  @override
  Future<Result<String>> updatePost({
    required String postId,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
    Member? author,
  }) async {
    return ApiCallDecorator.wrap('PostRepository.updatePost', () async {
      try {
        // DataSource에서 현재 사용자 정보 및 권한 확인 처리
        final updatedPostId = await _dataSource.updatePost(
          postId: postId,
          title: title,
          content: content,
          hashTags: hashTags,
          imageUris: imageUris,
        );

        return Result.success(updatedPostId);
      } catch (e, st) {
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'postId': postId});
  }

  /* Delete */
  @override
  Future<Result<bool>> deletePost(String postId) async {
    return ApiCallDecorator.wrap('PostRepository.deletePost', () async {
      try {
        // DataSource에서 현재 사용자 정보 및 권한 확인 처리
        final success = await _dataSource.deletePost(postId);
        return Result.success(success);
      } catch (e, st) {
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'postId': postId});
  }
}
