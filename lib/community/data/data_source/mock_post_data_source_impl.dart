// lib/community/data/data_source/post_data_source_impl.dart
import 'dart:math';
import 'package:devlink_mobile_app/community/data/dto/hash_tag_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/like_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/member_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/post_dto.dart';
import 'package:devlink_mobile_app/community/module/util/board_type_enum.dart';

import 'post_data_source.dart';

class PostDataSourceImpl implements PostDataSource {
  @override
  Future<List<PostDto>> fetchPostList() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final rand = Random();

    return List.generate(30, (i) {
      final likeCnt = rand.nextInt(200);
      return PostDto(
        id: 'post_$i',
        title: '목 게시글 $i',
        content: '[Mock] 내용 $i',
        member: MemberDto(            // auth 완성 전까지 임시
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
        like: List.generate(
          likeCnt,
          (idx) => LikeDto(boardId: 'post_$i', memberId: 'u$idx'),
        ),
      );
    });
  }
}
