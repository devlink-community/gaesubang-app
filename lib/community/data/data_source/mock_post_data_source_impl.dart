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
        image: '',
      ),
      boardType: BoardType.free,
      createdAt: DateTime.now().subtract(Duration(minutes: i * 5)),
      hashTag: [
        HashTagDto(id: 't1', content: '#태그${i % 3}'),
        if (i.isEven) HashTagDto(id: 't2', content: '#인기'),
      ],
      like:
          List.generate(likeCnt, (idx) => LikeDto(boardId: 'post_$i', memberId: 'u$idx')),
    );
  }

  CommentDto _mockComment(String postId, int i) => CommentDto(
        boardId: postId,
        memberId: 'u$i',
        createdAt: DateTime(2025, 4, 28),
        content: '저도 참여하고 싶습니다!',
      );
}
