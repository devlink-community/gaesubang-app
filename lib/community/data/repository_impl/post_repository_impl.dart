// lib/community/data/repository_impl/post_repository_impl.dart
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/community/data/data_source/post_data_source.dart';
import 'package:devlink_mobile_app/community/data/mapper/post_mapper.dart';
import 'package:devlink_mobile_app/community/domain/model/comment.dart';
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/exception_mappers/auth_exception_mapper.dart';

class PostRepositoryImpl implements PostRepository {
  const PostRepositoryImpl({required PostDataSource dataSource})
    : _dataSource = dataSource;

  final PostDataSource _dataSource;

  // ✅ 헬퍼 메서드 추가
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /* ---------- List ---------- */
  @override
  Future<Result<List<Post>>> loadPostList() async {
    const operationName = 'PostRepository.loadPostList';
    AppLogger.communityInfo('게시글 목록 로드 요청');

    return ApiCallDecorator.wrap(operationName, () async {
      final startTime = DateTime.now();

      try {
        // DataSource에서 현재 사용자 정보 처리
        final postDtos = await _dataSource.fetchPostList();

        // DTO를 Model로 변환
        final posts = postDtos.toModelList();

        // 성능 로깅
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('게시글 목록 로드', duration);
        AppLogger.communityInfo('게시글 목록 로드 성공: ${posts.length}개');

        return Result.success(posts);
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('게시글 목록 로드 실패', duration);
        AppLogger.communityError('게시글 목록 로드 실패', error: e, stackTrace: st);

        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    });
  }

  /* ---------- Detail ---------- */
  @override
  Future<Result<Post>> getPostDetail(String id) async {
    const operationName = 'PostRepository.getPostDetail';
    AppLogger.communityInfo('게시글 상세 조회 요청: $id');

    return ApiCallDecorator.wrap(operationName, () async {
      final startTime = DateTime.now();

      try {
        final postDto = await _dataSource.fetchPostDetail(id);
        final post = postDto.toModel();

        // 성능 및 상세 로깅
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('게시글 상세 조회', duration);
        AppLogger.logState('PostDetail', {
          'postId': id,
          'title': _truncateText(post.title, 30),
          'authorId': post.authorId,
          'likeCount': post.likeCount,
          'commentCount': post.commentCount,
        });

        return Result.success(post);
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('게시글 상세 조회 실패', duration);
        AppLogger.communityError('게시글 상세 조회 실패: $id', error: e, stackTrace: st);

        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'postId': id});
  }

  /* ---------- Toggle ---------- */
  @override
  Future<Result<Post>> toggleLike(String id) async {
    const operationName = 'PostRepository.toggleLike';
    AppLogger.communityInfo('게시글 좋아요 토글 요청: $id');

    return ApiCallDecorator.wrap(operationName, () async {
      final startTime = DateTime.now();

      try {
        final postDto = await _dataSource.toggleLike(id);
        final post = postDto.toModel();

        // 성능 및 결과 로깅
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('좋아요 토글', duration);

        final likeStatus = post.isLikedByCurrentUser ? '추가' : '취소';
        AppLogger.communityInfo(
          '좋아요 $likeStatus 완료: $id (총 ${post.likeCount}개)',
        );

        return Result.success(post);
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('좋아요 토글 실패', duration);
        AppLogger.communityError('좋아요 토글 실패: $id', error: e, stackTrace: st);

        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'postId': id});
  }

  @override
  Future<Result<Post>> toggleBookmark(String id) async {
    const operationName = 'PostRepository.toggleBookmark';
    AppLogger.communityInfo('게시글 북마크 토글 요청: $id');

    return ApiCallDecorator.wrap(operationName, () async {
      final startTime = DateTime.now();

      try {
        final postDto = await _dataSource.toggleBookmark(id);
        final post = postDto.toModel();

        // 성능 및 결과 로깅
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('북마크 토글', duration);

        final bookmarkStatus = post.isBookmarkedByCurrentUser ? '추가' : '제거';
        AppLogger.communityInfo('북마크 $bookmarkStatus 완료: $id');

        return Result.success(post);
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('북마크 토글 실패', duration);
        AppLogger.communityError('북마크 토글 실패: $id', error: e, stackTrace: st);

        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'postId': id});
  }

  /* ---------- Comment ---------- */
  @override
  Future<Result<List<Comment>>> getComments(String id) async {
    const operationName = 'PostRepository.getComments';
    AppLogger.communityInfo('댓글 목록 조회 요청: $id');

    return ApiCallDecorator.wrap(operationName, () async {
      final startTime = DateTime.now();

      try {
        final commentDtos = await _dataSource.fetchComments(id);
        final comments = commentDtos.toModelList();

        // 성능 및 결과 로깅
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('댓글 목록 조회', duration);
        AppLogger.communityInfo('댓글 목록 조회 성공: $id (${comments.length}개)');

        return Result.success(comments);
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('댓글 목록 조회 실패', duration);
        AppLogger.communityError('댓글 목록 조회 실패: $id', error: e, stackTrace: st);

        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'postId': id});
  }

  @override
  Future<Result<List<Comment>>> createComment({
    required String postId,
    required String content,
  }) async {
    const operationName = 'PostRepository.createComment';
    AppLogger.logBox('댓글 작성', '게시글: $postId, 내용 길이: ${content.length}자');

    return ApiCallDecorator.wrap(operationName, () async {
      final startTime = DateTime.now();

      try {
        final commentDtos = await _dataSource.createComment(
          postId: postId,
          content: content,
        );
        final comments = commentDtos.toModelList();

        // 성능 및 결과 로깅
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('댓글 작성', duration);
        AppLogger.communityInfo('댓글 작성 성공: $postId (총 ${comments.length}개)');

        return Result.success(comments);
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('댓글 작성 실패', duration);
        AppLogger.communityError('댓글 작성 실패: $postId', error: e, stackTrace: st);

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
    const operationName = 'PostRepository.toggleCommentLike';
    AppLogger.communityInfo('댓글 좋아요 토글 요청: $postId/$commentId');

    return ApiCallDecorator.wrap(
      operationName,
      () async {
        final startTime = DateTime.now();

        try {
          final commentDto = await _dataSource.toggleCommentLike(
            postId,
            commentId,
          );
          final comment = commentDto.toModel();

          // 성능 및 결과 로깅
          final duration = DateTime.now().difference(startTime);
          AppLogger.logPerformance('댓글 좋아요 토글', duration);

          final likeStatus = comment.isLikedByCurrentUser ? '추가' : '취소';
          AppLogger.communityInfo(
            '댓글 좋아요 $likeStatus 완료: $commentId (총 ${comment.likeCount}개)',
          );

          return Result.success(comment);
        } catch (e, st) {
          final duration = DateTime.now().difference(startTime);
          AppLogger.logPerformance('댓글 좋아요 토글 실패', duration);
          AppLogger.communityError(
            '댓글 좋아요 토글 실패: $postId/$commentId',
            error: e,
            stackTrace: st,
          );

          return Result.error(AuthExceptionMapper.mapAuthException(e, st));
        }
      },
      params: {'postId': postId, 'commentId': commentId},
    );
  }

  /* ---------- Search ---------- */
  @override
  Future<Result<List<Post>>> searchPosts(String query) async {
    const operationName = 'PostRepository.searchPosts';
    AppLogger.logBox('게시글 검색', '검색어: "$query"');

    return ApiCallDecorator.wrap(operationName, () async {
      final startTime = DateTime.now();

      try {
        final postDtos = await _dataSource.searchPosts(query);

        // DTO를 Model로 변환
        final posts = postDtos.toModelList();

        // 성능 및 검색 결과 로깅
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('게시글 검색', duration);
        AppLogger.searchInfo(query, posts.length);

        // 검색 결과가 없는 경우 별도 로깅
        AppLogger.logIf(posts.isEmpty, '검색 결과 없음: "$query"');

        return Result.success(posts);
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('게시글 검색 실패', duration);
        AppLogger.communityError(
          '게시글 검색 실패: "$query"',
          error: e,
          stackTrace: st,
        );

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
    const operationName = 'PostRepository.createPost';

    // ✅ 수정된 부분 - 헬퍼 메서드 사용
    final titlePreview = _truncateText(title, 20);
    AppLogger.logBox(
      '게시글 작성',
      '제목: "$titlePreview" | '
          '내용: ${content.length}자 | '
          '태그: ${hashTags.length}개 | '
          '이미지: ${imageUris.length}개',
    );

    return ApiCallDecorator.wrap(operationName, () async {
      final startTime = DateTime.now();

      try {
        // DataSource에서 현재 사용자 정보 처리
        final createdPostId = await _dataSource.createPost(
          postId: postId,
          title: title,
          content: content,
          hashTags: hashTags,
          imageUris: imageUris,
        );

        // 성능 및 결과 로깅
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('게시글 작성', duration);
        AppLogger.logBanner('새 게시글 작성 완료! 🎉');
        AppLogger.communityInfo('게시글 작성 성공: $createdPostId');

        return createdPostId;
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('게시글 작성 실패', duration);
        AppLogger.communityError('게시글 작성 실패', error: e, stackTrace: st);

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
    const operationName = 'PostRepository.checkCommentsLikeStatus';
    AppLogger.debug('댓글 좋아요 상태 일괄 조회: $postId (${commentIds.length}개)');

    return ApiCallDecorator.wrap(
      operationName,
      () async {
        final startTime = DateTime.now();

        try {
          final result = await _dataSource.checkCommentsLikeStatus(
            postId,
            commentIds,
          );

          // 성능 로깅
          final duration = DateTime.now().difference(startTime);
          AppLogger.logPerformance('댓글 좋아요 상태 조회', duration);

          final likedCount = result.values.where((liked) => liked).length;
          AppLogger.debug(
            '댓글 좋아요 상태 조회 완료: $postId ($likedCount/${commentIds.length}개 좋아요)',
          );

          return Result.success(result);
        } catch (e, st) {
          final duration = DateTime.now().difference(startTime);
          AppLogger.logPerformance('댓글 좋아요 상태 조회 실패', duration);
          AppLogger.communityError(
            '댓글 좋아요 상태 조회 실패: $postId',
            error: e,
            stackTrace: st,
          );

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
    const operationName = 'PostRepository.updatePost';

    // ✅ 수정된 부분 - 헬퍼 메서드 사용
    final titlePreview = _truncateText(title, 20);
    AppLogger.logBox(
      '게시글 수정',
      '게시글: $postId | '
          '제목: "$titlePreview" | '
          '내용: ${content.length}자 | '
          '태그: ${hashTags.length}개 | '
          '이미지: ${imageUris.length}개',
    );

    return ApiCallDecorator.wrap(operationName, () async {
      final startTime = DateTime.now();

      try {
        // DataSource에서 현재 사용자 정보 및 권한 확인 처리
        final updatedPostId = await _dataSource.updatePost(
          postId: postId,
          title: title,
          content: content,
          hashTags: hashTags,
          imageUris: imageUris,
        );

        // 성능 및 결과 로깅
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('게시글 수정', duration);
        AppLogger.logBanner('게시글 수정 완료! ✨');
        AppLogger.communityInfo('게시글 수정 성공: $updatedPostId');

        return Result.success(updatedPostId);
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('게시글 수정 실패', duration);
        AppLogger.communityError(
          '게시글 수정 실패: $postId',
          error: e,
          stackTrace: st,
        );

        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'postId': postId});
  }

  /* Delete */
  @override
  Future<Result<bool>> deletePost(String postId) async {
    const operationName = 'PostRepository.deletePost';
    AppLogger.logBox('게시글 삭제', '게시글 삭제 요청: $postId');

    return ApiCallDecorator.wrap(operationName, () async {
      final startTime = DateTime.now();

      try {
        // DataSource에서 현재 사용자 정보 및 권한 확인 처리
        final success = await _dataSource.deletePost(postId);

        // 성능 및 결과 로깅
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('게시글 삭제', duration);

        if (success) {
          AppLogger.logBanner('게시글 삭제 완료! 🗑️');
          AppLogger.communityInfo('게시글 삭제 성공: $postId');
        } else {
          AppLogger.warning('게시글 삭제 실패: $postId (success=false)');
        }

        return Result.success(success);
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('게시글 삭제 실패', duration);
        AppLogger.communityError(
          '게시글 삭제 실패: $postId',
          error: e,
          stackTrace: st,
        );

        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'postId': postId});
  }
}
