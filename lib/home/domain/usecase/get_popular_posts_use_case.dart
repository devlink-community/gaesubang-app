import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetPopularPostsUseCase {
  final PostRepository _postRepository;

  GetPopularPostsUseCase({required PostRepository postRepository})
    : _postRepository = postRepository;

  Future<AsyncValue<List<Post>>> execute() async {
    try {
      // 전체 게시글 목록을 가져온 후 인기게시글 3개를 추출
      final result = await _postRepository.loadPostList();
      
      switch (result) {
        case Success(:final data):
          // 좋아요 수를 기준으로 정렬하여 상위 3개 추출
          final popularPosts = data
            ..sort((a, b) => b.likeCount.compareTo(a.likeCount));
          
          // 최대 3개까지만 반환
          final limitedPosts = popularPosts.take(3).toList();
          return AsyncData(limitedPosts);
          
        case Error(:final failure):
          return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
      }
    } catch (e, stackTrace) {
      return AsyncError(e, stackTrace);
    }
  }
}