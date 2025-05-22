// lib/community/domain/usecase/search_posts_use_case.dart
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SearchPostsUseCase {
  const SearchPostsUseCase({required PostRepository repo}) : _repo = repo;

  final PostRepository _repo;

  Future<AsyncValue<List<Post>>> execute(String query) async {
    try {
      // 쿼리가 빈 문자열이면 빈 목록 반환
      if (query.trim().isEmpty) {
        return const AsyncData(<Post>[]);
      }

      final result = await _repo.searchPosts(query);

      switch (result) {
        case Success(:final data):
          // ID 기준으로 중복 제거
          final uniquePosts = _removeDuplicatePosts(data);
          return AsyncData(uniquePosts);
        case Error(:final failure):
          return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
      }
    } catch (e, stackTrace) {
      return AsyncError(e, stackTrace);
    }
  }

  /// 게시글 ID를 기준으로 중복을 제거하는 메서드
  List<Post> _removeDuplicatePosts(List<Post> posts) {
    final Map<String, Post> uniquePostsMap = {};

    for (final post in posts) {
      // ID가 없는 게시글은 제외 (방어 코드)
      if (post.id.isNotEmpty) {
        // 동일한 ID가 이미 있다면 더 완전한 데이터를 우선 선택
        final existingPost = uniquePostsMap[post.id];
        if (existingPost == null || _isMoreComplete(post, existingPost)) {
          uniquePostsMap[post.id] = post;
        }
      }
    }

    // Map의 values를 List로 변환하여 반환
    return uniquePostsMap.values.toList();
  }

  /// 두 게시글 중 어느 것이 더 완전한 데이터인지 판단하는 메서드
  bool _isMoreComplete(Post newPost, Post existingPost) {
    // 기본적으로는 최신 데이터를 우선하되,
    // 더 많은 정보를 가진 게시글을 우선 선택

    // 1. 제목이나 내용이 더 길거나 완전한 것을 우선
    final newPostContentLength =
        (newPost.title.length) + (newPost.content.length);
    final existingPostContentLength =
        (existingPost.title.length) + (existingPost.content.length);

    if (newPostContentLength > existingPostContentLength) {
      return true;
    }
    if (newPostContentLength < existingPostContentLength) {
      return false;
    }

    // 2. 해시태그나 미디어 URL이 더 많은 것을 우선
    final newPostMetaCount =
        (newPost.hashTags.length) + (newPost.imageUrls.length);
    final existingPostMetaCount =
        (existingPost.hashTags.length) + (existingPost.imageUrls.length);

    // 메타 정보가 더 많은 것을 우선, 같다면 기존 것을 유지
    return newPostMetaCount > existingPostMetaCount;
  }
}
