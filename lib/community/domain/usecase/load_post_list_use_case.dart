// lib/community/domain/usecase/load_post_list_use_case.dart
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';

class LoadPostListUseCase {
  const LoadPostListUseCase({required PostRepository repo}) : _repo = repo;
  final PostRepository _repo;

  Future<Result<List<Post>>> call() => _repo.loadPostList();
}
