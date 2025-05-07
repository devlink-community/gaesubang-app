// lib/community/presentation/community_detail/community_detail_state.dart
import 'package:devlink_mobile_app/community/domain/model/comment.dart';
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'community_detail_state.freezed.dart';

@freezed
class CommunityDetailState with _$CommunityDetailState {
  const CommunityDetailState({
    this.post = const AsyncLoading(),
    this.comments = const AsyncLoading(),
  });

  @override
  final AsyncValue<Post> post;
  @override
  final AsyncValue<List<Comment>> comments;
}
