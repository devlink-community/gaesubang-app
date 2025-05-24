// lib/community/module/community_di.dart (상단 import 부분 수정)
import 'package:devlink_mobile_app/community/data/data_source/mock_post_data_source_impl.dart';
import 'package:devlink_mobile_app/community/data/data_source/post_firebase_data_source.dart';
import 'package:devlink_mobile_app/community/domain/usecase/create_comment_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/create_post_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/delete_post_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/fetch_comments_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/fetch_post_detail_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/search_posts_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/toggle_bookmark_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/toggle_comment_like_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/toggle_like_use_case.dart';
import 'package:devlink_mobile_app/community/domain/usecase/update_post_use_case.dart';
import 'package:devlink_mobile_app/core/config/app_config.dart';
import 'package:devlink_mobile_app/core/firebase/firebase_providers.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/data_source/post_data_source.dart';
import '../data/repository_impl/post_repository_impl.dart';
import '../domain/repository/post_repository.dart';
import '../domain/usecase/load_post_list_use_case.dart';
import '../domain/usecase/switch_tab_use_case.dart';

part 'community_di.g.dart';

// === DataSource Providers ===

/// PostDataSource - AppConfig 플래그에 따라 Mock 또는 Firebase 선택
@Riverpod(keepAlive: true)
PostDataSource postDataSource(Ref ref) {
  if (AppConfig.useMockCommunity) {
    AppLogger.debug('Community DI: Mock DataSource 사용', tag: 'CommunityDI');
    return MockPostDataSourceImpl();
  } else {
    AppLogger.debug('Community DI: Firebase DataSource 사용', tag: 'CommunityDI');
    return PostFirebaseDataSource(
      firestore: ref.watch(firebaseFirestoreProvider),
      auth: ref.watch(firebaseAuthProvider),
    );
  }
}

// === Repository Providers === (나머지는 동일)

@riverpod
PostRepository postRepository(Ref ref) {
  return PostRepositoryImpl(dataSource: ref.watch(postDataSourceProvider));
}

// === UseCase Providers === (나머지는 동일)

@riverpod
LoadPostListUseCase loadPostListUseCase(Ref ref) {
  return LoadPostListUseCase(repo: ref.watch(postRepositoryProvider));
}

@riverpod
SwitchTabUseCase switchTabUseCase(Ref ref) {
  return SwitchTabUseCase();
}

@riverpod
FetchPostDetailUseCase fetchPostDetailUseCase(Ref ref) {
  return FetchPostDetailUseCase(repo: ref.watch(postRepositoryProvider));
}

@riverpod
ToggleLikeUseCase toggleLikeUseCase(Ref ref) {
  return ToggleLikeUseCase(repo: ref.watch(postRepositoryProvider));
}

@riverpod
ToggleBookmarkUseCase toggleBookmarkUseCase(Ref ref) {
  return ToggleBookmarkUseCase(repo: ref.watch(postRepositoryProvider));
}

@riverpod
CreateCommentUseCase createCommentUseCase(Ref ref) {
  return CreateCommentUseCase(repo: ref.watch(postRepositoryProvider));
}

@riverpod
FetchCommentsUseCase fetchCommentsUseCase(Ref ref) {
  return FetchCommentsUseCase(repo: ref.watch(postRepositoryProvider));
}

@riverpod
CreatePostUseCase createPostUseCase(Ref ref) {
  return CreatePostUseCase(repo: ref.watch(postRepositoryProvider));
}

@riverpod
SearchPostsUseCase searchPostsUseCase(Ref ref) {
  return SearchPostsUseCase(repo: ref.watch(postRepositoryProvider));
}

@riverpod
ToggleCommentLikeUseCase toggleCommentLikeUseCase(Ref ref) {
  return ToggleCommentLikeUseCase(repo: ref.watch(postRepositoryProvider));
}

@riverpod
UpdatePostUseCase updatePostUseCase(Ref ref) {
  return UpdatePostUseCase(repo: ref.watch(postRepositoryProvider));
}

@riverpod
DeletePostUseCase deletePostUseCase(Ref ref) {
  return DeletePostUseCase(repo: ref.watch(postRepositoryProvider));
}