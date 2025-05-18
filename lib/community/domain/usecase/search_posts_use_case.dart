// lib/community/domain/usecase/search_posts_use_case.dart

import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SearchPostsUseCase {
  const SearchPostsUseCase({required PostRepository repo}) : _repo = repo;
  final PostRepository _repo;

  Future<AsyncValue<List<Post>>> execute(String query) async {
    // 쿼리가 빈 문자열이면 빈 목록 반환
    if (query.trim().isEmpty) {
      return const AsyncData(<Post>[]);
    }
    
    final result = await _repo.searchPosts(query);
    
    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}