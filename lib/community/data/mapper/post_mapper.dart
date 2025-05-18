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
        userProfileImageUrl: userProfileImageUrl ?? '',
        boardType: _parseBoardType(boardType),
        createdAt: createdAt ?? DateTime.now(),
        hashTags: (hashTags ?? []),
        imageUrls: (imageUrls ?? []),
        like: (like ?? []).map((e) => e.toModel()).toList(),
        comment: (comment ?? []).map((e) => e.toModel()).toList(),
      );
      
  // 문자열로 저장된 boardType을 enum으로 변환
  BoardType _parseBoardType(dynamic boardTypeValue) {
    if (boardTypeValue is BoardType) {
      return boardTypeValue;
    }
    
    if (boardTypeValue is String) {
      try {
        return BoardType.values.firstWhere(
          (e) => e.name == boardTypeValue,
          orElse: () => BoardType.free,
        );
      } catch (_) {
        return BoardType.free;
      }
    }
    
    return BoardType.free;
  }
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