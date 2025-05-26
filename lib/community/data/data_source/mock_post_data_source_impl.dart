// lib/community/data/data_source/mock_post_data_source_impl.dart
import 'package:devlink_mobile_app/community/data/dto/post_comment_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/post_dto.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/messages/community_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';

import 'post_data_source.dart';

class MockPostDataSourceImpl implements PostDataSource {
  // 현재 사용자 ID (Mock 환경에서는 고정값 사용)
  static const String _currentUserId = 'user1';

  // 목 데이터 (새로운 DTO 구조 사용)
  static final List<PostDto> _mockPosts = [
    PostDto(
      id: 'post1',
      authorId: 'user1',
      authorNickname: '홍길동',
      authorPosition: '프론트엔드 개발자',
      userProfileImage: 'https://api.dicebear.com/6.x/micah/png?seed=author1',
      title: '개발팀 앱 제작',
      content: '플러터로 개발하는 방법을 공유합니다.',
      mediaUrls: ['https://picsum.photos/id/237/400/300'],
      createdAt: TimeFormatter.nowInSeoul().subtract(
        const Duration(days: 2, hours: 4),
      ),
      hashTags: ['텀프로젝트', 'flutter'],
    ),
    PostDto(
      id: 'post2',
      authorId: 'user2',
      authorNickname: '김영희',
      authorPosition: '백엔드 개발자',
      userProfileImage: 'https://api.dicebear.com/6.x/micah/png?seed=author2',
      title: '이것은 인기 게시글 입니다.',
      content: '인기 게시글 내용입니다.',
      mediaUrls: ['https://picsum.photos/id/1/400/300'],
      createdAt: TimeFormatter.nowInSeoul().subtract(
        const Duration(days: 1, hours: 6),
      ),
      hashTags: ['인기글'],
    ),
    PostDto(
      id: 'post3',
      authorId: 'user3',
      authorNickname: '박철수',
      authorPosition: '데이터 분석가',
      userProfileImage: 'https://api.dicebear.com/6.x/micah/png?seed=author3',
      title: '개발자커뮤니티 앱 제작',
      content: '함께 개발할 분을 찾습니다.',
      mediaUrls: ['https://picsum.photos/id/20/400/300'],
      createdAt: TimeFormatter.nowInSeoul().subtract(
        const Duration(days: 3, hours: 12),
      ),
      hashTags: ['텀프로젝트', 'flutter'],
    ),
  ];

  // 댓글 Mock 데이터
  static final Map<String, List<PostCommentDto>> _mockComments = {
    'post1': [
      PostCommentDto(
        id: 'comment1',
        userId: 'user1',
        userName: '홍길동',
        userProfileImage: 'https://api.dicebear.com/6.x/micah/png?seed=user1',
        text: '댓글 내용 1',
        createdAt: TimeFormatter.nowInSeoul().subtract(
          const Duration(hours: 1),
        ),
        likeCount: 3,
      ),
      PostCommentDto(
        id: 'comment2',
        userId: 'user2',
        userName: '김영희',
        userProfileImage: 'https://api.dicebear.com/6.x/micah/png?seed=user2',
        text: '댓글 내용 2',
        createdAt: TimeFormatter.nowInSeoul().subtract(
          const Duration(hours: 2),
        ),
        likeCount: 1,
      ),
    ],
    'post2': [
      PostCommentDto(
        id: 'comment3',
        userId: 'user3',
        userName: '박철수',
        userProfileImage: 'https://api.dicebear.com/6.x/micah/png?seed=user3',
        text: '댓글 내용 3',
        createdAt: TimeFormatter.nowInSeoul().subtract(
          const Duration(hours: 3),
        ),
        likeCount: 0,
      ),
    ],
  };

  // 좋아요 상태 저장 (postId -> Set<userId>)
  static final Map<String, Set<String>> _likedPosts = {
    'post1': {'user2', 'user3'},
    'post2': {'user1'},
  };

  // 북마크 상태 저장 (userId -> Set<postId>)
  static final Map<String, Set<String>> _bookmarkedPosts = {
    'user1': {'post2'},
    'user2': {'post1'},
  };

  // 댓글 좋아요 상태 저장 (commentId -> Set<userId>)
  static final Map<String, Set<String>> _likedComments = {
    'comment1': {'user2', 'user3', 'user4'},
    'comment2': {'user1'},
  };

  @override
  Future<List<PostDto>> fetchPostList() async {
    return ApiCallDecorator.wrap('MockPost.fetchPostList', () async {
      // 데이터 로딩 시뮬레이션
      await Future.delayed(const Duration(milliseconds: 500));

      // 복사본 생성 및 추가 정보 설정
      return _mockPosts.map((post) {
        final postId = post.id ?? '';
        final likeCount = _likedPosts[postId]?.length ?? 0;
        final commentCount = _mockComments[postId]?.length ?? 0;
        final isLikedByCurrentUser =
            _likedPosts[postId]?.contains(_currentUserId) ?? false;
        final isBookmarkedByCurrentUser =
            _bookmarkedPosts[_currentUserId]?.contains(postId) ?? false;

        return post.copyWith(
          likeCount: likeCount,
          commentCount: commentCount, // 댓글 수 추가
          isLikedByCurrentUser: isLikedByCurrentUser,
          isBookmarkedByCurrentUser: isBookmarkedByCurrentUser,
        );
      }).toList();
    });
  }

  @override
  Future<PostDto> fetchPostDetail(String postId) async {
    return ApiCallDecorator.wrap('MockPost.fetchPostDetail', () async {
      // 로딩 시뮬레이션
      await Future.delayed(const Duration(milliseconds: 300));

      // 해당 ID의 게시글 찾기
      final post = _mockPosts.firstWhere(
        (post) => post.id == postId,
        orElse: () => throw Exception(CommunityErrorMessages.postNotFound),
      );

      // 좋아요 수 및 사용자 상태 설정
      final likeCount = _likedPosts[postId]?.length ?? 0;
      final commentCount = _mockComments[postId]?.length ?? 0; // 댓글 수 추가
      final isLikedByCurrentUser =
          _likedPosts[postId]?.contains(_currentUserId) ?? false;
      final isBookmarkedByCurrentUser =
          _bookmarkedPosts[_currentUserId]?.contains(postId) ?? false;

      // 정보 추가하여 반환
      return post.copyWith(
        likeCount: likeCount,
        commentCount: commentCount, // 댓글 수 추가
        isLikedByCurrentUser: isLikedByCurrentUser,
        isBookmarkedByCurrentUser: isBookmarkedByCurrentUser,
      );
    }, params: {'postId': postId});
  }

  @override
  Future<PostDto> toggleLike(String postId) async {
    return ApiCallDecorator.wrap('MockPost.toggleLike', () async {
      await Future.delayed(const Duration(milliseconds: 200));

      // 좋아요 상태 토글
      final likedUsers = _likedPosts[postId] ?? <String>{};

      if (likedUsers.contains(_currentUserId)) {
        likedUsers.remove(_currentUserId);
      } else {
        likedUsers.add(_currentUserId);
      }

      _likedPosts[postId] = likedUsers;

      // 업데이트된 게시글 반환
      return await fetchPostDetail(postId);
    }, params: {'postId': postId});
  }

  @override
  Future<PostDto> toggleBookmark(String postId) async {
    return ApiCallDecorator.wrap('MockPost.toggleBookmark', () async {
      await Future.delayed(const Duration(milliseconds: 200));

      // 북마크 상태 토글
      final userBookmarks = _bookmarkedPosts[_currentUserId] ?? <String>{};

      if (userBookmarks.contains(postId)) {
        userBookmarks.remove(postId);
      } else {
        userBookmarks.add(postId);
      }

      _bookmarkedPosts[_currentUserId] = userBookmarks;

      // 업데이트된 게시글 반환
      return await fetchPostDetail(postId);
    }, params: {'postId': postId});
  }

  @override
  Future<List<PostCommentDto>> fetchComments(String postId) async {
    return ApiCallDecorator.wrap('MockPost.fetchComments', () async {
      await Future.delayed(const Duration(milliseconds: 300));

      final comments = _mockComments[postId] ?? [];

      // 좋아요 정보 추가하여 복사본 반환
      return comments.map((comment) {
        final commentId = comment.id ?? '';
        final isLikedByCurrentUser =
            _likedComments[commentId]?.contains(_currentUserId) ?? false;
        return comment.copyWith(isLikedByCurrentUser: isLikedByCurrentUser);
      }).toList();
    }, params: {'postId': postId});
  }

  @override
  Future<List<PostCommentDto>> createComment({
    required String postId,
    required String content,
  }) async {
    return ApiCallDecorator.wrap('MockPost.createComment', () async {
      await Future.delayed(const Duration(milliseconds: 200));

      // Mock 사용자 정보 (실제로는 현재 로그인된 사용자 정보 사용)
      const mockUserName = '현재사용자';
      const mockUserProfileImage =
          'https://api.dicebear.com/6.x/micah/png?seed=current';

      // 새 댓글 생성
      final newComment = PostCommentDto(
        id: 'comment_${TimeFormatter.nowInSeoul().millisecondsSinceEpoch}',
        userId: _currentUserId,
        userName: mockUserName,
        userProfileImage: mockUserProfileImage,
        text: content,
        createdAt: TimeFormatter.nowInSeoul(),
        likeCount: 0,
        isLikedByCurrentUser: false, // 생성 시 좋아요 상태는 false
      );

      // 댓글 목록에 추가
      final comments = _mockComments[postId] ?? [];
      comments.insert(0, newComment); // 새 댓글을 맨 앞에 추가
      _mockComments[postId] = comments;

      // 업데이트된 댓글 목록 반환
      return List.from(comments);
    }, params: {'postId': postId});
  }

  @override
  Future<PostCommentDto> toggleCommentLike(
    String postId,
    String commentId,
  ) async {
    return ApiCallDecorator.wrap('MockPost.toggleCommentLike', () async {
      await Future.delayed(const Duration(milliseconds: 200));

      // 좋아요 상태 토글
      final likedUsers = _likedComments[commentId] ?? <String>{};

      bool newLikeStatus = false;
      if (likedUsers.contains(_currentUserId)) {
        likedUsers.remove(_currentUserId);
        newLikeStatus = false;
      } else {
        likedUsers.add(_currentUserId);
        newLikeStatus = true;
      }

      _likedComments[commentId] = likedUsers;

      // 해당 댓글 찾기
      PostCommentDto? targetComment;

      for (final comments in _mockComments.values) {
        for (final comment in comments) {
          if (comment.id == commentId) {
            targetComment = comment;
            break;
          }
        }
        if (targetComment != null) break;
      }

      if (targetComment == null) {
        throw Exception(CommunityErrorMessages.commentLoadFailed);
      }

      // 좋아요 수와 상태 업데이트하여 반환
      return targetComment.copyWith(
        likeCount: likedUsers.length,
        isLikedByCurrentUser: newLikeStatus,
      );
    }, params: {'postId': postId, 'commentId': commentId});
  }

  @override
  Future<Map<String, bool>> checkCommentsLikeStatus(
    String postId,
    List<String> commentIds,
  ) async {
    return ApiCallDecorator.wrap(
      'MockPost.checkCommentsLikeStatus',
      () async {
        await Future.delayed(const Duration(milliseconds: 200));

        final Map<String, bool> result = {};

        // 각 댓글의 좋아요 상태 확인
        for (final commentId in commentIds) {
          final likedUsers = _likedComments[commentId] ?? <String>{};
          result[commentId] = likedUsers.contains(_currentUserId);
        }

        return result;
      },
      params: {'postId': postId, 'commentCount': commentIds.length},
    );
  }

  @override
  Future<String> createPost({
    required String postId,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  }) async {
    return ApiCallDecorator.wrap('MockPost.createPost', () async {
      await Future.delayed(const Duration(milliseconds: 400));

      // Mock 현재 사용자 정보
      const mockAuthorNickname = '현재사용자';
      const mockAuthorPosition = '개발자';
      const mockUserProfileImage =
          'https://api.dicebear.com/6.x/micah/png?seed=current';

      // 새 게시글 생성
      final newPost = PostDto(
        id: postId,
        authorId: _currentUserId,
        authorNickname: mockAuthorNickname,
        authorPosition: mockAuthorPosition,
        userProfileImage: mockUserProfileImage,
        title: title,
        content: content,
        mediaUrls: imageUris.map((uri) => uri.toString()).toList(),
        createdAt: TimeFormatter.nowInSeoul(),
        hashTags: hashTags,
        likeCount: 0,
        isLikedByCurrentUser: false,
        isBookmarkedByCurrentUser: false,
      );

      // 목 데이터에 추가 (맨 앞에 추가하여 최신 게시글이 위에 오도록)
      _mockPosts.insert(0, newPost);

      // 생성된 게시글 ID 반환
      return postId;
    }, params: {'postId': postId});
  }

  @override
  Future<List<PostDto>> searchPosts(String query) async {
    return ApiCallDecorator.wrap('MockPost.searchPosts', () async {
      await Future.delayed(const Duration(milliseconds: 300));

      if (query.trim().isEmpty) {
        return [];
      }

      // 검색어가 제목, 내용, 태그 중 하나에 포함된 게시글 필터링
      final lowercaseQuery = query.toLowerCase();

      final results =
          _mockPosts
              .where((post) {
                final titleMatch = (post.title ?? '').toLowerCase().contains(
                  lowercaseQuery,
                );
                final contentMatch = (post.content ?? '')
                    .toLowerCase()
                    .contains(lowercaseQuery);
                final tagMatch = (post.hashTags ?? []).any(
                  (tag) => tag.toLowerCase().contains(lowercaseQuery),
                );

                return titleMatch || contentMatch || tagMatch;
              })
              .map((post) {
                // 좋아요 수 및 사용자 상태 포함
                final postId = post.id ?? '';
                final likeCount = _likedPosts[postId]?.length ?? 0;
                final isLikedByCurrentUser =
                    _likedPosts[postId]?.contains(_currentUserId) ?? false;
                final isBookmarkedByCurrentUser =
                    _bookmarkedPosts[_currentUserId]?.contains(postId) ?? false;

                return post.copyWith(
                  likeCount: likeCount,
                  isLikedByCurrentUser: isLikedByCurrentUser,
                  isBookmarkedByCurrentUser: isBookmarkedByCurrentUser,
                );
              })
              .toList();

      // 복사본 반환
      return results;
    }, params: {'query': query});
  }

  // 새로 추가된 메서드 구현
  @override
  Future<Map<String, bool>> checkUserLikeStatus(List<String> postIds) async {
    return ApiCallDecorator.wrap('MockPost.checkUserLikeStatus', () async {
      await Future.delayed(const Duration(milliseconds: 200));

      final Map<String, bool> result = {};

      // 각 게시글에 대한 좋아요 상태 확인
      for (final postId in postIds) {
        final likedUsers = _likedPosts[postId] ?? <String>{};
        result[postId] = likedUsers.contains(_currentUserId);
      }

      return result;
    }, params: {'postIds': postIds.length});
  }

  @override
  Future<Map<String, bool>> checkUserBookmarkStatus(
    List<String> postIds,
  ) async {
    return ApiCallDecorator.wrap('MockPost.checkUserBookmarkStatus', () async {
      await Future.delayed(const Duration(milliseconds: 200));

      final Map<String, bool> result = {};

      // 각 게시글에 대한 북마크 상태 확인
      final userBookmarks = _bookmarkedPosts[_currentUserId] ?? <String>{};

      for (final postId in postIds) {
        result[postId] = userBookmarks.contains(postId);
      }

      return result;
    }, params: {'postIds': postIds.length});
  }

  @override
  Future<String> updatePost({
    required String postId,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  }) async {
    return ApiCallDecorator.wrap('MockPost.updatePost', () async {
      await Future.delayed(const Duration(milliseconds: 500));

      // 게시글 존재 확인
      final postIndex = _mockPosts.indexWhere((post) => post.id == postId);
      if (postIndex < 0) {
        throw Exception(CommunityErrorMessages.postNotFound);
      }

      // 권한 확인 (작성자만 수정 가능)
      final post = _mockPosts[postIndex];
      if (post.authorId != _currentUserId) {
        throw Exception(CommunityErrorMessages.noPermissionEdit);
      }

      // 기존 게시글 복사 후 업데이트
      final updatedPost = post.copyWith(
        title: title,
        content: content,
        hashTags: hashTags,
        mediaUrls: imageUris.map((uri) => uri.toString()).toList(),
        // likeCount, commentCount 등 기존 값은 유지
      );

      // 목록에서 업데이트
      _mockPosts[postIndex] = updatedPost;

      return postId;
    }, params: {'postId': postId});
  }

  @override
  Future<bool> deletePost(String postId) async {
    return ApiCallDecorator.wrap('MockPost.deletePost', () async {
      await Future.delayed(const Duration(milliseconds: 300));

      // 게시글 존재 확인
      final postIndex = _mockPosts.indexWhere((post) => post.id == postId);
      if (postIndex < 0) {
        throw Exception(CommunityErrorMessages.postNotFound);
      }

      // 권한 확인 (작성자만 삭제 가능)
      final post = _mockPosts[postIndex];
      if (post.authorId != _currentUserId) {
        throw Exception(CommunityErrorMessages.noPermissionDelete);
      }

      // 게시글 삭제
      _mockPosts.removeAt(postIndex);

      // 관련 댓글 삭제
      _mockComments.remove(postId);

      // 관련 좋아요 삭제
      _likedPosts.remove(postId);

      // 북마크에서도 제거
      _bookmarkedPosts.forEach((user, posts) {
        posts.remove(postId);
      });

      return true;
    }, params: {'postId': postId});
  }
}
