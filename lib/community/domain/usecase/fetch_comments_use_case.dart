import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/community/domain/model/comment.dart';
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';

class FetchCommentsUseCase {
  const FetchCommentsUseCase({required PostRepository repo}) : _repo = repo;
  final PostRepository _repo;

  Future<Result<List<Comment>>> execute(String postId) =>
      _repo.getComments(postId);
}