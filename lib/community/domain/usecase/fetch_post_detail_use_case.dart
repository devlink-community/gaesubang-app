// lib/community/domain/usecase/fetch_post_detail_use_case.dart

import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';

class FetchPostDetailUseCase {
  const FetchPostDetailUseCase({required PostRepository repo}) : _repo = repo;
  final PostRepository _repo;

  Future<Result<Post>> execute(String postId) => _repo.getPostDetail(postId);
}
