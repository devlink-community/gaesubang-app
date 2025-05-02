import 'package:devlink_mobile_app/community/data/data_source/mock_post_data_source_impl.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/data_source/post_data_source.dart';

import '../data/repository_impl/post_repository_impl.dart';
import '../domain/repository/post_repository.dart';
import '../domain/usecase/load_post_list_use_case.dart';
import '../domain/usecase/switch_tab_use_case.dart';

part 'community_di.g.dart';

@riverpod
PostDataSource postDataSource(Ref ref) => PostDataSourceImpl();

@riverpod
PostRepository postRepository(Ref ref) =>
    PostRepositoryImpl(dataSource: ref.watch(postDataSourceProvider));

@riverpod
LoadPostListUseCase loadPostListUseCase(Ref ref) =>
    LoadPostListUseCase(repo: ref.watch(postRepositoryProvider));

@riverpod
SwitchTabUseCase switchTabUseCase(Ref ref) => SwitchTabUseCase();
