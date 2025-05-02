// lib/community/data/repository_impl/post_repository_impl.dart
import 'package:devlink_mobile_app/community/data/data_source/post_data_source.dart';
import 'package:devlink_mobile_app/community/data/mapper/post_mapper.dart';
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';


class PostRepositoryImpl implements PostRepository {
  const PostRepositoryImpl({required PostDataSource dataSource}) : _remote = dataSource;

  final PostDataSource _remote;

  @override
  Future<Result<List<Post>>> loadPostList() async {
    try {
      final dto = await _remote.fetchPostList();
      return Result.success(dto.toModelList());
    } catch (e) {
      return Result.error(mapExceptionToFailure(e, StackTrace.fromString(e.toString())));
    }
  }
}
