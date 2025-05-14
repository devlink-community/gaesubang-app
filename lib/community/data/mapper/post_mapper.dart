// lib/community/data/mapper/post_mapper.dart
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/community/data/dto/comment_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/like_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/member_dto.dart';
import 'package:devlink_mobile_app/community/data/dto/post_dto.dart';
import 'package:devlink_mobile_app/community/domain/model/comment.dart';
import 'package:devlink_mobile_app/community/domain/model/like.dart';
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/module/util/board_type_enum.dart';

extension PostDtoMapper on PostDto {
  Post toModel() => Post(
        id: id ?? '',
        title: title ?? '',
        content: content ?? '',
        member: member?.toModel() ??
            Member(id: '', email: '', nickname: '', uid: '', onAir: false, image: ''),
        userProfileImageUrl: userProfileImage ?? '',
        boardType: boardType ?? BoardType.free,
        createdAt: createdAt ?? DateTime.now(),
        hashTags: (hashTags ?? []),
        imageUrls: (mediaUrls ?? []),
        like: (like ?? []).map((e) => e.toModel()).toList(),
        comment: (comment ?? []).map((e) => e.toModel()).toList(),
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

extension on LikeDto {
  Like toModel() => Like(
        userId: userId ?? '', 
        userName: userName ?? '',
        timestamp: timestamp ?? DateTime.now(),
      );
}

extension on CommentDto {
  Comment toModel() => Comment(
        userId: userId ?? '',
        userName: userName ?? '', 
        userProfileImage: userProfileImage ?? '',
        text: text ?? '',
        createdAt: createdAt ?? DateTime.now(),
        likeCount: likeCount ?? 0,
      );
}

extension PostDtoListX on List<PostDto> {
  List<Post> toModelList() => map((e) => e.toModel()).toList();
}