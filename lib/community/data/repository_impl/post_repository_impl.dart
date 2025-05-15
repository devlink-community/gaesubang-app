// lib/community/data/repository_impl/post_repository_impl.dart
import 'package:devlink_mobile_app/community/data/mapper/comment_mapper.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/community/data/data_source/post_data_source.dart';
import 'package:devlink_mobile_app/community/data/mapper/post_mapper.dart';
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/domain/model/comment.dart';
import 'package:devlink_mobile_app/community/domain/repository/post_repository.dart';

class PostRepositoryImpl implements PostRepository {
  const PostRepositoryImpl({required PostDataSource dataSource})
    : _remote = dataSource;

  final PostDataSource _remote;

  /* ---------- List ---------- */
  @override
  Future<Result<List<Post>>> loadPostList() async {
    try {
      final dto = await _remote.fetchPostList();
      return Result.success(dto.toModelList());
    } catch (e) {
      return Result.error(
        mapExceptionToFailure(e, StackTrace.fromString(e.toString())),
      );
    }
  }

  /* ---------- Detail ---------- */
  @override
  Future<Result<Post>> getPostDetail(String id) async =>
      _wrap(() => _remote.fetchPostDetail(id).then((e) => e.toModel()));

  /* ---------- Toggle ---------- */
  @override
  Future<Result<Post>> toggleLike(String id) async =>
      _wrap(() => _remote.toggleLike(id).then((e) => e.toModel()));

  @override
  Future<Result<Post>> toggleBookmark(String id) async =>
      _wrap(() => _remote.toggleBookmark(id).then((e) => e.toModel()));

  /* ---------- Comment ---------- */
  @override
  Future<Result<List<Comment>>> getComments(String id) async =>
      _wrap(() async => (await _remote.fetchComments(id)).toModelList());

  @override
  Future<Result<List<Comment>>> createComment({
    required String postId,
    required String memberId,
    required String content,
  }) async => _wrap(
    () async =>
        (await _remote.createComment(
          postId: postId,
          memberId: memberId,
          content: content,
        )).toModelList(),
  );

  /* ---------- NEW ---------- */
  @override
  Future<String> createPost({
    required String postId,
    required String title,
    required String content,
    required List<String> hashTags,
    required List<Uri> imageUris,
  }) => _remote.createPost(
    postId: postId,
    title: title,
    content: content,
    hashTags: hashTags,
    imageUris: imageUris,
  );

  @override
Future<Result<List<Post>>> searchPosts(String query) async {
  try {
    final posts = await _remote.searchPosts(query);
    return Result.success(posts.toModelList());
  } catch (e) {
    return Result.error(
      mapExceptionToFailure(e, StackTrace.fromString(e.toString())),
    );
  }
}

  /* ---------- Helper ---------- */
  Future<Result<T>> _wrap<T>(Future<T> Function() fn) async {
    try {
      return Result.success(await fn());
    } catch (e) {
      return Result.error(
        mapExceptionToFailure(e, StackTrace.fromString(e.toString())),
      );
    }
  }
}
