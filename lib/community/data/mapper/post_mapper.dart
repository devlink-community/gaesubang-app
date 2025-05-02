// lib/community/data/mapper/post_mapper.dart
// import 'package:auth/domain/model/member.dart';
import 'package:devlink_mobile_app/community/data/dto/hash_tag_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/like_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/member_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/post_dto.dart';
import 'package:devlink_mobile_app/community/domain/model/hash_tag.dart';
import 'package:devlink_mobile_app/community/domain/model/like.dart';
import 'package:devlink_mobile_app/community/domain/model/post.dart';

extension PostDtoMapper on PostDto {
  Post toModel() => Post(
        id: id ?? '',
        title: title ?? '',
        content: content ?? '',
        member: member?.toModel() ??
            Member(id: '', email: '', nickname: '', uid: '', onAir: false, image: ''),
        boardType: boardType ?? BoardType.free,
        createdAt: createdAt ?? DateTime.now(),
        hashTag: (hashTag ?? []).map((e) => e.toModel()).toList(),
        like: (like ?? []).map((e) => e.toModel()).toList(),
      );
}

extension on MemberDto {
  Member toModel() => Member(
        id: id ?? '',
        email: email ?? '',
        nickname: nickname ?? '',
        uid: uid ?? '',
        onAir: onAir ?? false,
        image: image ?? '',
      );
}

extension on HashTagDto {
  HashTag toModel() => HashTag(id: id ?? '', content: content ?? '');
}

extension on LikeDto {
  Like toModel() => Like(boardId: boardId ?? '', memberId: memberId ?? '');
}

extension PostDtoListX on List<PostDto> {
  List<Post> toModelList() => map((e) => e.toModel()).toList();
}
