// lib/community/domain/usecase/delete_post_use_case.dart
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DeletePostUseCase {
  final PostRepository _repo;

  DeletePostUseCase({required PostRepository repo}) : _repo = repo;

  Future<AsyncValue<bool>> execute(String postId) async {
    final result = await _repo.deletePost(postId);

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
