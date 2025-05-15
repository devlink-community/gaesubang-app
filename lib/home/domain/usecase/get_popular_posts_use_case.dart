import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/home/domain/repository/home_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetPopularPostsUseCase {
  final HomeRepository _repository;

  GetPopularPostsUseCase({required HomeRepository repository})
    : _repository = repository;

  Future<AsyncValue<List<Post>>> execute() async {
    final result = await _repository.getPopularPosts();

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
