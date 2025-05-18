import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/home/domain/model/notice.dart';

abstract interface class HomeRepository {
  /// 공지사항 목록 조회
  Future<Result<List<Notice>>> getNotices();

  /// 인기 게시글 목록 조회
  Future<Result<List<Post>>> getPopularPosts();
}
