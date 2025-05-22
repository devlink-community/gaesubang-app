// lib/community/domain/usecase/create_post_use_case.dart
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CreatePostUseCase {
  final PostRepository _repo;

  CreatePostUseCase({required PostRepository repo}) : _repo = repo;

  Future<AsyncValue<String>> execute({
    required String postId,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  }) async {
    try {
      final result = await _repo.createPost(
        postId: postId,
        title: title,
        content: content,
        hashTags: hashTags,
        imageUris: imageUris,
      );
      return AsyncData(result);
    } catch (e) {
      return AsyncError(e, StackTrace.current);
    }
  }
}
