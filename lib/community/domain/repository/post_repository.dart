// lib/community/domain/repository/post_repository.dart
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/core/result/result.dart';



abstract interface class PostRepository {
  Future<Result<List<Post>>> loadPostList();
}
