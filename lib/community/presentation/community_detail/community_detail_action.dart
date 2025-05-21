// lib/community/presentation/community_detail/community_detail_action.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'community_detail_action.freezed.dart';

@freezed
sealed class CommunityDetailAction with _$CommunityDetailAction {
  const factory CommunityDetailAction.refresh() = Refresh;
  const factory CommunityDetailAction.toggleLike() = ToggleLike;
  const factory CommunityDetailAction.toggleBookmark() = ToggleBookmark;
  const factory CommunityDetailAction.addComment(String content) = AddComment;
  const factory CommunityDetailAction.toggleCommentLike(String commentId) =
      ToggleCommentLike;
  const factory CommunityDetailAction.editPost() = EditPost;
  const factory CommunityDetailAction.deletePost() = DeletePost;
}
