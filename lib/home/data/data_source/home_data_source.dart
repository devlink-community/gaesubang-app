import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/home/domain/model/notice.dart';

abstract interface class HomeDataSource {
  /// 공지사항 목록 조회
  Future<List<Notice>> fetchNotices();

  /// 인기 게시글 목록 조회
  Future<List<Post>> fetchPopularPosts();
}
