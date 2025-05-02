// lib/community/domain/model/post.dart
import 'package:devlink_mobile_app/community/domain/model/hash_tag.dart';
import 'package:devlink_mobile_app/community/domain/model/like.dart';
import 'package:devlink_mobile_app/community/module/util/board_type_enum.dart';
import 'package:freezed_annotation/freezed_annotation.dart';



part 'post.freezed.dart';

@freezed
abstract class Post with _$Post {
  const factory Post({
    required String id,
    required String title,
    required String content,
    required Member member,
    required BoardType boardType,
    required DateTime createdAt,
    @Default(<HashTag>[]) List<HashTag> hashTag,
    @Default(<Like>[])    List<Like>    like,
  }) = _Post;
}


