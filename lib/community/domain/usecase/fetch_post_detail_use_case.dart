// lib/community/domain/usecase/fetch_post_detail_use_case.dart

import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FetchPostDetailUseCase {
  const FetchPostDetailUseCase({required PostRepository repo}) : _repo = repo;
  final PostRepository _repo;

  Future<AsyncValue<Post>> execute(String postId) async {
    final result = await _repo.getPostDetail(postId);
    
    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}