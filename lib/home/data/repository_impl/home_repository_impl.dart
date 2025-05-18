import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/home/data/data_source/home_data_source.dart';
import 'package:devlink_mobile_app/home/domain/model/notice.dart';
import 'package:devlink_mobile_app/home/domain/repository/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeDataSource _dataSource;

  HomeRepositoryImpl({required HomeDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Result<List<Notice>>> getNotices() async {
    try {
      final notices = await _dataSource.fetchNotices();
      return Result.success(notices);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Future<Result<List<Post>>> getPopularPosts() async {
    try {
      final posts = await _dataSource.fetchPopularPosts();
      return Result.success(posts);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }
}
