import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';

/// 게시글 작성 요청
class CreatePostUseCase {
  CreatePostUseCase({required PostRepository repo}) : _repo = repo;
  final PostRepository _repo;

  /// **Result 타입이 아니라** 실제 새 Post ID(String) 를 반환하도록 설계
  Future<String> execute({
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  }) async {
    // Post 모델을 조립하거나 DTO 로 보낼 수도 있음
    // 여기서는 repository에 위임한다고 가정
    return _repo.createPost(
      title: title,
      content: content,
      hashTags: hashTags,
      imageUris: imageUris,
    );
  }
}
