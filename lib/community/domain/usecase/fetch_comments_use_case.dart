// lib/community/domain/usecase/fetch_comments_use_case.dart

import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/community/domain/model/comment.dart';
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FetchCommentsUseCase {
  const FetchCommentsUseCase({required PostRepository repo}) : _repo = repo;
  final PostRepository _repo;

  Future<AsyncValue<List<Comment>>> execute(String postId) async {
    final result = await _repo.getComments(postId);
    
    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}