import 'package:devlink_mobile_app/community/domain/model/comment.dart';
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';

class CreateCommentUseCase {
  const CreateCommentUseCase({required PostRepository repo}) : _repo = repo;
  final PostRepository _repo;

  Future<Result<List<Comment>>> execute({
    required String postId,
    required String memberId,
    required String content,
  }) =>
      _repo.createComment(
        postId: postId,
        memberId: memberId,
        content: content,
      );
}