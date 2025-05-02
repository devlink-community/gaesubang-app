// lib/community/data/data_source/post_data_source.dart
import 'package:devlink_mobile_app/community/data/dto/post_dto.dart';

abstract interface class PostDataSource {
  /// 모든 게시글을 한 번에 가져온다.
  Future<List<PostDto>> fetchPostList();
}
