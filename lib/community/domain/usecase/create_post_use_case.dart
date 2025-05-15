// lib/community/domain/usecase/create_post_use_case.dart
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';

class CreatePostUseCase {
  final PostRepository _repository;

  CreatePostUseCase({required PostRepository repo}) : _repository = repo;

  Future<String> execute({
    required String postId,  // 추가된 매개변수
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  }) async {
    try {
      final createdPostId = await _repository.createPost(
        postId: postId,  // ID 전달
        title: title,
        content: content,
        hashTags: hashTags,
        imageUris: imageUris,
      );
      
      return createdPostId;
    } catch (e) {
      throw Exception('게시글 생성에 실패했습니다: $e');
    }
  }
}