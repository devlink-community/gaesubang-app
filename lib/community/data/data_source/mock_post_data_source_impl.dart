// lib/community/data/data_source/mock_post_data_source_impl.dart
import 'dart:math';
import 'package:devlink_mobile_app/community/data/dto/comment_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/like_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/member_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/post_dto.dart';
import 'package:devlink_mobile_app/community/module/util/board_type_enum.dart';
import 'post_data_source.dart';

class PostDataSourceImpl implements PostDataSource {
  final _rand = Random();

  // 목 데이터 (홈 화면의 인기 게시글과 일치하도록 설정)
  final List<PostDto> _mockPosts = [
    PostDto(
      id: 'post1',
      title: '개발팀 앱 제작',
      content: '플러터로 개발하는 방법을 공유합니다.',
      member: MemberDto(
        id: 'author1',
        email: 'author1@example.com',
        nickname: '개수발',
        uid: 'author1-uid',
        image: 'https://api.dicebear.com/6.x/micah/png?seed=author1',
      ),
      userProfileImageUrl:
          'https://api.dicebear.com/6.x/micah/png?seed=author1',
      boardType: BoardType.free.name,
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
      hashTags: ['텀프로젝트', 'flutter'],
      imageUrls: ['https://picsum.photos/id/237/400/300'],
      like: List.generate(
        7,
        (index) => LikeDto(
          userId: 'user$index',
          userName: '사용자$index',
          timestamp: DateTime.now().subtract(Duration(hours: index)),
        ),
      ),
      comment: List.generate(
        7,
        (index) => CommentDto(
          userId: 'user$index',
          userName: '사용자$index',
          userProfileImage:
              'https://api.dicebear.com/6.x/micah/png?seed=user$index',
          text: '댓글 내용 $index',
          createdAt: DateTime.now().subtract(Duration(hours: index)),
        ),
      ),
    ),
    PostDto(
      id: 'post2',
      title: '이것은 인기 게시글 입니다.',
      content: '인기 게시글 내용입니다.',
      member: MemberDto(
        id: 'author2',
        email: 'author2@example.com',
        nickname: '문성용',
        uid: 'author2-uid',
        image: 'https://api.dicebear.com/6.x/micah/png?seed=author2',
      ),
      userProfileImageUrl:
          'https://api.dicebear.com/6.x/micah/png?seed=author2',
      boardType: BoardType.free.name,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
      hashTags: ['인기글'],
      imageUrls: ['https://picsum.photos/id/1/400/300'],
      like: List.generate(
        4,
        (index) => LikeDto(
          userId: 'user${index + 10}',
          userName: '사용자${index + 10}',
          timestamp: DateTime.now().subtract(Duration(hours: index + 2)),
        ),
      ),
      comment: List.generate(
        3,
        (index) => CommentDto(
          userId: 'user${index + 10}',
          userName: '사용자${index + 10}',
          userProfileImage:
              'https://api.dicebear.com/6.x/micah/png?seed=user${index + 10}',
          text: '댓글 $index',
          createdAt: DateTime.now().subtract(Duration(hours: index + 2)),
        ),
      ),
    ),
    PostDto(
      id: 'post3',
      title: '개발자커뮤니티 앱 제작',
      content: '함께 개발할 분을 찾습니다.',
      member: MemberDto(
        id: 'author3',
        email: 'author3@example.com',
        nickname: '강지원',
        uid: 'author3-uid',
        image: 'https://api.dicebear.com/6.x/micah/png?seed=author3',
      ),
      userProfileImageUrl:
          'https://api.dicebear.com/6.x/micah/png?seed=author3',
      boardType: BoardType.qna.name,
      createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 12)),
      hashTags: ['텀프로젝트', 'flutter'],
      imageUrls: ['https://picsum.photos/id/20/400/300'],
      like: List.generate(
        7,
        (index) => LikeDto(
          userId: 'user${index + 20}',
          userName: '사용자${index + 20}',
          timestamp: DateTime.now().subtract(Duration(hours: index + 5)),
        ),
      ),
      comment: List.generate(
        7,
        (index) => CommentDto(
          userId: 'user${index + 20}',
          userName: '사용자${index + 20}',
          userProfileImage:
              'https://api.dicebear.com/6.x/micah/png?seed=user${index + 20}',
          text: '댓글입니다 $index',
          createdAt: DateTime.now().subtract(Duration(hours: index + 5)),
          likeCount: index,
        ),
      ),
    ),
  ];

  @override
  Future<List<PostDto>> fetchPostList() async {
    // 데이터 로딩 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockPosts;
  }

  @override
  Future<PostDto> fetchPostDetail(String postId) async {
    // 로딩 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 300));

    // 해당 ID의 게시글 찾기
    final post = _mockPosts.firstWhere(
      (post) => post.id == postId,
      orElse: () => throw Exception('게시글을 찾을 수 없습니다: $postId'),
    );

    return post;
  }

  @override
  Future<PostDto> toggleLike(String postId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final postIndex = _mockPosts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) {
      throw Exception('게시글을 찾을 수 없습니다: $postId');
    }

    // 현재 사용자 ID (임시로 'user1' 사용)
    const currentUserId = 'user1';
    const currentUserName = '현재 사용자';

    final post = _mockPosts[postIndex];

    // 좋아요 토글 처리
    final likes = List<LikeDto>.from(post.like ?? []);
    final existingLikeIndex = likes.indexWhere(
      (like) => like.userId == currentUserId,
    );

    if (existingLikeIndex >= 0) {
      // 이미 좋아요를 누른 경우, 좋아요 취소
      likes.removeAt(existingLikeIndex);
    } else {
      // 좋아요 추가
      likes.add(
        LikeDto(
          userId: currentUserId,
          userName: currentUserName,
          timestamp: DateTime.now(),
        ),
      );
    }

    // 수정된 게시글 반환
    final updatedPost = post.copyWith(like: likes);
    _mockPosts[postIndex] = updatedPost;

    return updatedPost;
  }

  @override
  Future<PostDto> toggleBookmark(String postId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // 실제 북마크 기능은 여기서 구현하지 않음
    // 해당 ID의 게시글만 반환
    return fetchPostDetail(postId);
  }

  @override
  Future<List<CommentDto>> fetchComments(String postId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final post = await fetchPostDetail(postId);
    return post.comment ?? [];
  }

  @override
  Future<List<CommentDto>> createComment({
    required String postId,
    required String memberId,
    required String content,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final postIndex = _mockPosts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) {
      throw Exception('게시글을 찾을 수 없습니다: $postId');
    }

    // 새 댓글 생성
    final newComment = CommentDto(
      userId: memberId,
      userName: '현재 사용자',
      userProfileImage:
          'https://api.dicebear.com/6.x/micah/png?seed=currentUser',
      text: content,
      createdAt: DateTime.now(),
      likeCount: 0,
    );

    // 게시글에 댓글 추가
    final post = _mockPosts[postIndex];
    final comments = List<CommentDto>.from(post.comment ?? []);
    comments.insert(0, newComment); // 새 댓글을 맨 앞에 추가

    // 게시글 업데이트
    _mockPosts[postIndex] = post.copyWith(comment: comments);

    return comments;
  }

  @override
  Future<String> createPost({
    required String postId,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // 새 게시글 생성
    final newPost = PostDto(
      id: postId,
      title: title,
      content: content,
      member: MemberDto(
        id: 'user1',
        email: 'user1@example.com',
        nickname: '현재 사용자',
        uid: 'user1-uid',
        image: 'https://api.dicebear.com/6.x/micah/png?seed=user1',
      ),
      userProfileImageUrl: 'https://api.dicebear.com/6.x/micah/png?seed=user1',
      boardType: BoardType.free.name,
      createdAt: DateTime.now(),
      hashTags: hashTags,
      imageUrls: imageUris.map((uri) => uri.toString()).toList(),
      like: [],
      comment: [],
    );

    // 목 데이터에 추가
    _mockPosts.insert(0, newPost); // 최신 게시글이 맨 앞에 오도록

    return postId;
  }

  @override
  Future<List<PostDto>> searchPosts(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // 검색어가 제목, 내용, 태그 중 하나에 포함된 게시글 필터링
    final results =
        _mockPosts.where((post) {
          final titleMatch =
              post.title?.toLowerCase().contains(query.toLowerCase()) ?? false;
          final contentMatch =
              post.content?.toLowerCase().contains(query.toLowerCase()) ??
              false;
          final tagMatch =
              post.hashTags?.any(
                (tag) => tag.toLowerCase().contains(query.toLowerCase()),
              ) ??
              false;

          return titleMatch || contentMatch || tagMatch;
        }).toList();

    return results;
  }

  // /* ---------- 목록 ---------- */
  // @override
  // Future<List<PostDto>> fetchPostList() async {
  //   await Future<void>.delayed(const Duration(milliseconds: 500));
  //   return List.generate(30, _mock);
  // }

  // /* ---------- 상세 ---------- */
  // @override
  // Future<PostDto> fetchPostDetail(String postId) async {
  //   await Future<void>.delayed(const Duration(milliseconds: 400));
  //   return _mock(int.parse(postId.split('_').last));
  // }

  // /* ---------- Toggle ---------- */
  // @override
  // Future<PostDto> toggleLike(String postId) async {
  //   await Future<void>.delayed(const Duration(milliseconds: 250));
  //   final dto = await fetchPostDetail(postId);
  //   dto.like?.add(
  //     LikeDto(userId: 'user_me', userName: '현재 사용자', timestamp: DateTime.now()),
  //   );
  //   return dto;
  // }
  //
  // @override
  // Future<PostDto> toggleBookmark(String postId) async {
  //   await Future<void>.delayed(const Duration(milliseconds: 250));
  //   return fetchPostDetail(postId); // 북마크 상태는 별도 DTO 필드가 없으므로 그대로 반환
  // }

  // /* ---------- 댓글 ---------- */
  // @override
  // Future<List<CommentDto>> fetchComments(String postId) async {
  //   await Future<void>.delayed(const Duration(milliseconds: 300));
  //   return List.generate(7, (i) => _mockComment(postId, i));
  // }
  //
  // @override
  // Future<List<CommentDto>> createComment({
  //   required String postId,
  //   required String memberId,
  //   required String content,
  // }) async {
  //   await Future<void>.delayed(const Duration(milliseconds: 200));
  //   final list = await fetchComments(postId);
  //   return [
  //     CommentDto(
  //       userId: memberId,
  //       userName: "현재 사용자",
  //       userProfileImage:
  //           "https://i.namu.wiki/i/R0AhIJhNi8fkU2Al72pglkrT8QenAaCJd1as-d_iY6MC8nub1iI5VzIqzJlLa-1uzZm--TkB-KHFiT-P-t7bEg.webp",
  //       text: content,
  //       createdAt: DateTime.now(),
  //       likeCount: 0,
  //     ),
  //     ...list,
  //   ];
  // }
  //
  // /* ---------- NEW ---------- */
  // @override
  // Future<String> createPost({
  //   required String title,
  //   required String content,
  //   required List<String> hashTags,
  //   required List<Uri> imageUris,
  // }) async {
  //   await Future<void>.delayed(const Duration(milliseconds: 400));
  //   // 실제 API 호출 자리. 여기서는 새 random id 반환
  //   final newId = 'post_${_rand.nextInt(100000)}';
  //   return newId;
  // }
  //
  // /* ---------- Mock Helpers ---------- */
  // PostDto _mock(int i) {
  //   final likeCnt = _rand.nextInt(200);
  //   return PostDto(
  //     id: 'post_$i',
  //     title: '목 게시글 $i',
  //     content: '[Mock] 내용 $i',
  //     member: MemberDto(
  //       id: 'u$i',
  //       email: 'user$i@mail.com',
  //       nickname: 'user$i',
  //       uid: 'uid_$i',
  //       onAir: i.isEven,
  //       image:
  //           'https://i.namu.wiki/i/R0AhIJhNi8fkU2Al72pglkrT8QenAaCJd1as-d_iY6MC8nub1iI5VzIqzJlLa-1uzZm--TkB-KHFiT-P-t7bEg.webp',
  //     ),
  //     userProfileImage:
  //         'https://i.namu.wiki/i/R0AhIJhNi8fkU2Al72pglkrT8QenAaCJd1as-d_iY6MC8nub1iI5VzIqzJlLa-1uzZm--TkB-KHFiT-P-t7bEg.webp',
  //     boardType: BoardType.free,
  //     createdAt: DateTime.now().subtract(Duration(minutes: i * 5)),
  //     hashTags: ['#태그${i % 3}', if (i.isEven) '#인기'],
  //     mediaUrls:
  //         i % 3 == 0
  //             ? [
  //               'https://i.namu.wiki/i/R0AhIJhNi8fkU2Al72pglkrT8QenAaCJd1as-d_iY6MC8nub1iI5VzIqzJlLa-1uzZm--TkB-KHFiT-P-t7bEg.webp',
  //             ]
  //             : [],
  //     like: List.generate(
  //       likeCnt,
  //       (idx) => LikeDto(
  //         userId: 'u$idx',
  //         userName: 'user$idx',
  //         timestamp: DateTime.now().subtract(Duration(hours: idx)),
  //       ),
  //     ),
  //     comment: [_mockComment('post_$i', i)],
  //   );
  // }
  //
  // CommentDto _mockComment(String postId, int i) => CommentDto(
  //   userId: 'u$i',
  //   userName: '사용자$i',
  //   userProfileImage:
  //       'https://i.namu.wiki/i/R0AhIJhNi8fkU2Al72pglkrT8QenAaCJd1as-d_iY6MC8nub1iI5VzIqzJlLa-1uzZm--TkB-KHFiT-P-t7bEg.webp',
  //   text: '저도 참여하고 싶습니다!',
  //   createdAt: DateTime(2025, 4, 28),
  //   likeCount: _rand.nextInt(50),
  // );
}
