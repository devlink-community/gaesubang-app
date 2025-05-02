// lib/community/domain/model/post.dart
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/community/domain/model/hash_tag.dart';
import 'package:devlink_mobile_app/community/domain/model/like.dart';
import 'package:devlink_mobile_app/community/module/util/board_type_enum.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';

@freezed
class Post with _$Post {
  const Post({
    required this.id,
    required this.title,
    required this.content,
    required this.member,
    required this.boardType,
    required this.createdAt,
    this.hashTag = const <HashTag>[],
    this.like = const <Like>[],
  });

  @override
  final String id;
  @override
  final String title;
  @override
  final String content;
  @override
  final Member member;
  @override
  final BoardType boardType;
  @override
  final DateTime createdAt;
  @override
  final List<HashTag> hashTag;
  @override
  final List<Like> like;
}
