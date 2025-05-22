// lib/community/domain/usecase/update_post_use_case.dart
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UpdatePostUseCase {
  final PostRepository _repo;

  UpdatePostUseCase({required PostRepository repo}) : _repo = repo;

  Future<AsyncValue<String>> execute({
    required String postId,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  }) async {
    final result = await _repo.updatePost(
      postId: postId,
      title: title,
      content: content,
      hashTags: hashTags,
      imageUris: imageUris,
    );

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
