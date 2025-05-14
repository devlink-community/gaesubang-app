// lib/community/domain/usecase/search_posts_use_case.dart

import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SearchPostsUseCase {
  const SearchPostsUseCase({required PostRepository repo}) : _repo = repo;
  final PostRepository _repo;

  Future<AsyncValue<List<Post>>> execute(String query) async {
    // 1. 전체 게시글 목록을 가져오기
    final result = await _repo.loadPostList();
    
    // 2. switch 패턴 매칭을 사용하여 결과 처리
    switch (result) {
      case Success(:final data):
        // 3. 검색어로 필터링
        final filteredPosts = data.where((post) {
          final titleMatch = post.title.toLowerCase().contains(query.toLowerCase());
          final contentMatch = post.content.toLowerCase().contains(query.toLowerCase());
          final hashTagMatch = post.hashTags.any((tag) => 
              tag.toLowerCase().contains(query.toLowerCase()));
          
          return titleMatch || contentMatch || hashTagMatch;
        }).toList();
        
        return AsyncData(filteredPosts);
        
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}