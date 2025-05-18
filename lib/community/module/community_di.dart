// lib/community/module/community_di.dart
import 'package:devlink_mobile_app/community/data/data_source/mock_post_data_source_impl.dart';
import 'package:devlink_mobile_app/community/domain/usecase/create_comment_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/create_post_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/fetch_comments_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/fetch_post_detail_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/search_posts_use_case.dart'; // 새로 추가
import 'package:devlink_mobile_app/community/domain/usecase/toggle_bookmark_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/toggle_like_use_case.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/data_source/post_data_source.dart';
import '../data/repository_impl/post_repository_impl.dart';
import '../domain/repository/post_repository.dart';
import '../domain/usecase/load_post_list_use_case.dart';
import '../domain/usecase/switch_tab_use_case.dart';

part 'community_di.g.dart';

// 데이터소스 - 싱글톤처럼 관리
@Riverpod(keepAlive: true)
PostDataSource postDataSource(Ref ref) {
  print('Provider: Creating PostDataSource instance');
  final instance = PostDataSourceImpl();
  return instance;
}
// 데이터소스
// @riverpod
// PostDataSource postDataSource(Ref ref) => PostDataSourceImpl();

// @riverpod
// PostDataSource postDataSource(Ref ref) => PostFirebaseDataSource();

// 레포지토리
@riverpod
PostRepository postRepository(Ref ref) =>
    PostRepositoryImpl(dataSource: ref.watch(postDataSourceProvider));

// 유즈케이스
@riverpod
LoadPostListUseCase loadPostListUseCase(Ref ref) =>
    LoadPostListUseCase(repo: ref.watch(postRepositoryProvider));

@riverpod
SwitchTabUseCase switchTabUseCase(Ref ref) => SwitchTabUseCase();

@riverpod
FetchPostDetailUseCase fetchPostDetailUseCase(Ref ref) =>
    FetchPostDetailUseCase(repo: ref.watch(postRepositoryProvider));

@riverpod
ToggleLikeUseCase toggleLikeUseCase(Ref ref) =>
    ToggleLikeUseCase(repo: ref.watch(postRepositoryProvider));

@riverpod
ToggleBookmarkUseCase toggleBookmarkUseCase(Ref ref) =>
    ToggleBookmarkUseCase(repo: ref.watch(postRepositoryProvider));

@riverpod
CreateCommentUseCase createCommentUseCase(Ref ref) =>
    CreateCommentUseCase(repo: ref.watch(postRepositoryProvider));

@riverpod
FetchCommentsUseCase fetchCommentsUseCase(Ref ref) =>
    FetchCommentsUseCase(repo: ref.watch(postRepositoryProvider));

@riverpod
CreatePostUseCase createPostUseCase(Ref ref) =>
    CreatePostUseCase(repo: ref.watch(postRepositoryProvider));

@riverpod
SearchPostsUseCase searchPostsUseCase(Ref ref) =>
    SearchPostsUseCase(repo: ref.watch(postRepositoryProvider));
