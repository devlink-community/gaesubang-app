// lib/community/data/data_source/mock_post_data_source_impl.dart
import 'package:devlink_mobile_app/community/data/dto/post_comment_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/post_dto.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/messages/community_error_messages.dart';

import 'post_data_source.dart';

class MockPostDataSourceImpl implements PostDataSource {
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
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
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
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
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
      createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 12)),
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
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        likeCount: 3,
      ),
      PostCommentDto(
        id: 'comment2',
        userId: 'user2',
        userName: '김영희',
        userProfileImage: 'https://api.dicebear.com/6.x/micah/png?seed=user2',
        text: '댓글 내용 2',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
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
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
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

  @override
  Future<List<PostDto>> fetchPostList() async {
    return ApiCallDecorator.wrap('MockPost.fetchPostList', () async {
      // 데이터 로딩 시뮬레이션
      await Future.delayed(const Duration(milliseconds: 500));

      // 복사본 반환 (불변성 유지)
      return List.from(_mockPosts);
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

      return post;
    }, params: {'postId': postId});
  }

  @override
  Future<PostDto> toggleLike(
    String postId,
    String userId,
    String userName,
  ) async {
    return ApiCallDecorator.wrap('MockPost.toggleLike', () async {
      await Future.delayed(const Duration(milliseconds: 200));

      // 좋아요 상태 토글
      final likedUsers = _likedPosts[postId] ?? <String>{};

      if (likedUsers.contains(userId)) {
        likedUsers.remove(userId);
      } else {
        likedUsers.add(userId);
      }

      _likedPosts[postId] = likedUsers;

      // 업데이트된 게시글 반환
      return await fetchPostDetail(postId);
    }, params: {'postId': postId, 'userId': userId});
  }

  @override
  Future<PostDto> toggleBookmark(String postId, String userId) async {
    return ApiCallDecorator.wrap('MockPost.toggleBookmark', () async {
      await Future.delayed(const Duration(milliseconds: 200));

      // 북마크 상태 토글
      final userBookmarks = _bookmarkedPosts[userId] ?? <String>{};

      if (userBookmarks.contains(postId)) {
        userBookmarks.remove(postId);
      } else {
        userBookmarks.add(postId);
      }

      _bookmarkedPosts[userId] = userBookmarks;

      // 업데이트된 게시글 반환
      return await fetchPostDetail(postId);
    }, params: {'postId': postId, 'userId': userId});
  }

  @override
  Future<List<PostCommentDto>> fetchComments(String postId) async {
    return ApiCallDecorator.wrap('MockPost.fetchComments', () async {
      await Future.delayed(const Duration(milliseconds: 300));

      final comments = _mockComments[postId] ?? [];
      // 복사본 반환 (불변성 유지)
      return List.from(comments);
    }, params: {'postId': postId});
  }

  @override
  Future<List<PostCommentDto>> createComment({
    required String postId,
    required String userId,
    required String userName,
    required String userProfileImage,
    required String content,
  }) async {
    return ApiCallDecorator.wrap('MockPost.createComment', () async {
      await Future.delayed(const Duration(milliseconds: 200));

      // 새 댓글 생성
      final newComment = PostCommentDto(
        id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        userName: userName,
        userProfileImage: userProfileImage,
        text: content,
        createdAt: DateTime.now(),
        likeCount: 0,
      );

      // 댓글 목록에 추가
      final comments = _mockComments[postId] ?? [];
      comments.insert(0, newComment); // 새 댓글을 맨 앞에 추가
      _mockComments[postId] = comments;

      // 업데이트된 댓글 목록 반환
      return List.from(comments);
    }, params: {'postId': postId, 'userId': userId});
  }

  @override
  Future<String> createPost({
    required String postId,
    required String authorId,
    required String authorNickname,
    required String authorPosition,
    required String userProfileImage,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  }) async {
    return ApiCallDecorator.wrap('MockPost.createPost', () async {
      await Future.delayed(const Duration(milliseconds: 400));

      // 새 게시글 생성
      final newPost = PostDto(
        id: postId,
        authorId: authorId,
        authorNickname: authorNickname,
        authorPosition: authorPosition,
        userProfileImage: userProfileImage,
        title: title,
        content: content,
        mediaUrls: imageUris.map((uri) => uri.toString()).toList(),
        createdAt: DateTime.now(),
        hashTags: hashTags,
      );

      // 목 데이터에 추가 (맨 앞에 추가하여 최신 게시글이 위에 오도록)
      _mockPosts.insert(0, newPost);

      // 생성된 게시글 ID 반환
      return postId;
    }, params: {'postId': postId, 'authorId': authorId});
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
          _mockPosts.where((post) {
            final titleMatch = (post.title ?? '').toLowerCase().contains(
              lowercaseQuery,
            );
            final contentMatch = (post.content ?? '').toLowerCase().contains(
              lowercaseQuery,
            );
            final tagMatch = (post.hashTags ?? []).any(
              (tag) => tag.toLowerCase().contains(lowercaseQuery),
            );

            return titleMatch || contentMatch || tagMatch;
          }).toList();

      // 복사본 반환
      return List.from(results);
    }, params: {'query': query});
  }
}
