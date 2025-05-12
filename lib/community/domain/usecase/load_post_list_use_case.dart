// lib/community/domain/usecase/load_post_list_use_case.dart

import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LoadPostListUseCase {
  const LoadPostListUseCase({required PostRepository repo}) : _repo = repo;
  final PostRepository _repo;

  Future<AsyncValue<List<Post>>> execute() async {
    final result = await _repo.loadPostList();
    
    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}