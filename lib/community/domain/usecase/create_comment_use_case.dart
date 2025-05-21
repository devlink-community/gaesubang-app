// lib/community/domain/usecase/create_comment_use_case.dart

import 'package:devlink_mobile_app/community/domain/model/comment.dart';
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CreateCommentUseCase {
  const CreateCommentUseCase({required PostRepository repo}) : _repo = repo;
  final PostRepository _repo;

  Future<AsyncValue<List<Comment>>> execute({
    required String postId,
    required String content,
  }) async {
    final result = await _repo.createComment(postId: postId, content: content);

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
