// lib/community/domain/usecase/update_post_use_case.dart
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UpdatePostUseCase {
  const UpdatePostUseCase({required PostRepository repo}) : _repo = repo;
  final PostRepository _repo;

  Future<AsyncValue<String>> execute({
    required String postId,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
    Member? author,
  }) async {
    final result = await _repo.updatePost(
      postId: postId,
      title: title,
      content: content,
      hashTags: hashTags,
      imageUris: imageUris,
      author: author,
    );

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
