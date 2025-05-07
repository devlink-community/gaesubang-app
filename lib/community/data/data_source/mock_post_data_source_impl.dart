// lib/community/data/data_source/post_data_source_impl.dart
import 'dart:math';
import 'package:devlink_mobile_app/community/data/dto/hash_tag_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/like_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/member_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/post_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/comment_dto.dart';
import 'package:devlink_mobile_app/community/module/util/board_type_enum.dart';
import 'post_data_source.dart';

class PostDataSourceImpl implements PostDataSource {
  final _rand = Random();

  /* ---------- 목록 ---------- */
  @override
  Future<List<PostDto>> fetchPostList() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return List.generate(30, _mock);
  }

  /* ---------- 상세 ---------- */
  @override
  Future<PostDto> fetchPostDetail(String postId) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _mock(int.parse(postId.split('_').last));
  }

  /* ---------- Toggle ---------- */
  @override
  Future<PostDto> toggleLike(String postId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final dto = await fetchPostDetail(postId);
    dto.like?.add(LikeDto(boardId: postId, memberId: 'me'));
    return dto;
  }

  @override
  Future<PostDto> toggleBookmark(String postId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return fetchPostDetail(postId); // 북마크 상태는 별도 DTO 필드가 없으므로 그대로 반환
  }

  /* ---------- 댓글 ---------- */
  @override
  Future<List<CommentDto>> fetchComments(String postId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.generate(7, (i) => _mockComment(postId, i));
  }

  @override
  Future<List<CommentDto>> createComment({
    required String postId,
    required String memberId,
    required String content,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final list = await fetchComments(postId);
    return [
      CommentDto(
        boardId: postId,
        memberId: memberId,
        createdAt: DateTime.now(),
        content: content,
      ),
      ...list,
    ];
  }

  /* ---------- NEW ---------- */
  @override
  Future<String> createPost({
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // 실제 API 호출 자리. 여기서는 새 random id 반환
    final newId = 'post_${_rand.nextInt(100000)}';
    return newId;
  }

  /* ---------- Mock Helpers ---------- */
  PostDto _mock(int i) {
    final likeCnt = _rand.nextInt(200);
    return PostDto(
      id: 'post_$i',
      title: '목 게시글 $i',
      content: '[Mock] 내용 $i',
      member: MemberDto(
        id: 'u$i',
        email: 'user$i@mail.com',
        nickname: 'user$i',
        uid: 'uid_$i',
        onAir: i.isEven,
        image:
            'https://i.namu.wiki/i/R0AhIJhNi8fkU2Al72pglkrT8QenAaCJd1as-d_iY6MC8nub1iI5VzIqzJlLa-1uzZm--TkB-KHFiT-P-t7bEg.webp',
      ),
      boardType: BoardType.free,
      createdAt: DateTime.now().subtract(Duration(minutes: i * 5)),
      hashTag: [
        HashTagDto(id: 't1', content: '#태그${i % 3}'),
        if (i.isEven) HashTagDto(id: 't2', content: '#인기'),
      ],
      like: List.generate(
        likeCnt,
        (idx) => LikeDto(boardId: 'post_$i', memberId: 'u$idx'),
      ),
      comment: [_mockComment('post_$i', i)],
      image:
          "https://i.namu.wiki/i/R0AhIJhNi8fkU2Al72pglkrT8QenAaCJd1as-d_iY6MC8nub1iI5VzIqzJlLa-1uzZm--TkB-KHFiT-P-t7bEg.webp",
    );
  }

  CommentDto _mockComment(String postId, int i) => CommentDto(
    boardId: postId,
    memberId: 'u$i',
    createdAt: DateTime(2025, 4, 28),
    content: '저도 참여하고 싶습니다!',
  );
}
