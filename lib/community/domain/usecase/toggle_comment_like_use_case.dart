// lib/community/domain/usecase/toggle_comment_like_use_case.dart
import 'package:devlink_mobile_app/community/domain/model/comment.dart';
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ToggleCommentLikeUseCase {
  final PostRepository _repo;

  ToggleCommentLikeUseCase({required PostRepository repo}) : _repo = repo;

  Future<AsyncValue<Comment>> execute(String postId, String commentId) async {
    final result = await _repo.toggleCommentLike(postId, commentId);

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
