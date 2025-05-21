// lib/community/data/repository_impl/post_repository_impl.dart
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
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

  /* ---------- List - N+1 문제 해결 ---------- */
  @override
  Future<Result<List<Post>>> loadPostList() async {
    return ApiCallDecorator.wrap('PostRepository.loadPostList', () async {
      try {
        // 1. 현재 사용자 정보 확인
        final currentUser = _ref.read(currentUserProvider);
        if (currentUser == null) {
          throw Exception(CommunityErrorMessages.loginRequired);
        }
        // 2. 게시글 목록 기본 로드
        final postDtos = await _dataSource.fetchPostList(
          currentUserId: currentUser.uid,
        );

        // 3. 사용자가 로그인했고, 게시글이 있는 경우 상태 일괄 조회
        if (postDtos.isNotEmpty) {
          final postIds =
              postDtos
                  .map((dto) => dto.id ?? '')
                  .where((id) => id.isNotEmpty)
                  .toList();

          if (postIds.isNotEmpty) {
            // 3-1. 좋아요 상태 일괄 조회
            final likeStatuses = await _dataSource.checkUserLikeStatus(
              postIds,
              currentUser.uid,
            );

            // 3-2. 북마크 상태 일괄 조회
            final bookmarkStatuses = await _dataSource.checkUserBookmarkStatus(
              postIds,
              currentUser.uid,
            );

            // 3-3. DTO에 상태 정보 업데이트
            final updatedDtos =
                postDtos.map((dto) {
                  final postId = dto.id ?? '';
                  if (postId.isEmpty) return dto;

                  return dto.copyWith(
                    isLikedByCurrentUser: likeStatuses[postId] ?? false,
                    isBookmarkedByCurrentUser:
                        bookmarkStatuses[postId] ?? false,
                  );
                }).toList();

            // 3-4. 업데이트된 DTO로 모델 변환
            final posts = updatedDtos.toModelList();
            return Result.success(posts);
          }
        }

        // 4. 일괄 조회가 필요 없는 경우 기본 변환 (로그인하지 않았거나 게시글이 없는 경우)
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
        final currentUser = _ref.read(currentUserProvider);
        if (currentUser == null) {
          throw Exception(CommunityErrorMessages.loginRequired);
        }
        final postDto = await _dataSource.fetchPostDetail(
          id,
          currentUserId: currentUser.uid,
        );
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
        // Auth에서 현재 사용자 정보 가져오기
        final currentUser = _ref.read(currentUserProvider);
        if (currentUser == null) {
          throw Exception(CommunityErrorMessages.loginRequired);
        }
        final commentDtos = await _dataSource.fetchComments(
          id,
          currentUserId: currentUser.uid,
        );
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

  /* ---------- Search ---------- */
  @override
  Future<Result<List<Post>>> searchPosts(String query) async {
    return ApiCallDecorator.wrap('PostRepository.searchPosts', () async {
      try {
        // Auth에서 현재 사용자 정보 가져오기
        final currentUser = _ref.read(currentUserProvider);
        if (currentUser == null) {
          throw Exception(CommunityErrorMessages.loginRequired);
        }

        // 1. 검색 결과 기본 로드
        final postDtos = await _dataSource.searchPosts(
          query,
          currentUserId: currentUser.uid,
        );

        // 3. 사용자가 로그인했고, 검색 결과가 있는 경우 상태 일괄 조회
        if (postDtos.isNotEmpty) {
          final postIds =
              postDtos
                  .map((dto) => dto.id ?? '')
                  .where((id) => id.isNotEmpty)
                  .toList();

          if (postIds.isNotEmpty) {
            // 3-1. 좋아요 상태 일괄 조회
            final likeStatuses = await _dataSource.checkUserLikeStatus(
              postIds,
              currentUser.uid,
            );

            // 3-2. 북마크 상태 일괄 조회
            final bookmarkStatuses = await _dataSource.checkUserBookmarkStatus(
              postIds,
              currentUser.uid,
            );

            // 3-3. DTO에 상태 정보 업데이트
            final updatedDtos =
                postDtos.map((dto) {
                  final postId = dto.id ?? '';
                  if (postId.isEmpty) return dto;

                  return dto.copyWith(
                    isLikedByCurrentUser: likeStatuses[postId] ?? false,
                    isBookmarkedByCurrentUser:
                        bookmarkStatuses[postId] ?? false,
                  );
                }).toList();

            // 3-4. 업데이트된 DTO로 모델 변환
            final posts = updatedDtos.toModelList();
            return Result.success(posts);
          }
        }

        // 4. 일괄 조회가 필요 없는 경우 기본 변환
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
        // Auth에서 현재 사용자 정보 가져오기
        final currentUser = _ref.read(currentUserProvider);
        if (currentUser == null) {
          throw Exception(CommunityErrorMessages.loginRequired);
        }

        // 작성자 정보: 전달받은 author 또는 현재 사용자
        final authorNickname = author?.nickname ?? currentUser.nickname;
        final authorPosition = author?.position ?? currentUser.position ?? '';
        final userProfileImage = author?.image ?? currentUser.image;

        // 현재 사용자의 프로필 정보 가져오기
        final createdPostId = await _dataSource.createPost(
          postId: postId,
          authorId: currentUser.uid,
          authorNickname: authorNickname, // 전달받은 또는 현재 닉네임
          authorPosition: authorPosition, // 전달받은 또는 현재 직책
          userProfileImage: userProfileImage, // 전달받은 또는 현재 이미지
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
        // 1. 현재 사용자 정보 확인
        final currentUser = _ref.read(currentUserProvider);
        if (currentUser == null) {
          throw Exception(CommunityErrorMessages.loginRequired);
        }

        // 2. 작성자 정보: 전달받은 author 또는 현재 사용자
        final authorNickname = author?.nickname ?? currentUser.nickname;
        final authorPosition = author?.position ?? currentUser.position ?? '';
        final userProfileImage = author?.image ?? currentUser.image;

        // 3. DataSource 호출
        final updatedPostId = await _dataSource.updatePost(
          postId: postId,
          authorId: currentUser.uid, // 권한 확인용
          authorNickname: authorNickname,
          authorPosition: authorPosition,
          userProfileImage: userProfileImage,
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
        // 1. 현재 사용자 정보 확인
        final currentUser = _ref.read(currentUserProvider);
        if (currentUser == null) {
          throw Exception(CommunityErrorMessages.loginRequired);
        }

        // 2. DataSource 호출
        final success = await _dataSource.deletePost(postId, currentUser.uid);
        return Result.success(success);
      } catch (e, st) {
        return Result.error(AuthExceptionMapper.mapAuthException(e, st));
      }
    }, params: {'postId': postId});
  }
}
