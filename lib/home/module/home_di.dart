import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../group/module/group_di.dart';
import '../data/data_source/home_data_source.dart';
import '../data/data_source/mock_home_data_source_impl.dart';
import '../data/repository_impl/home_repository_impl.dart';
import '../domain/repository/home_repository.dart';
import '../domain/usecase/get_notices_use_case.dart';
import '../domain/usecase/get_popular_posts_use_case.dart';
import '../domain/usecase/get_user_joined_groups_use_case.dart';

part 'home_di.g.dart';

// DataSource Provider
@riverpod
HomeDataSource homeDataSource(Ref ref) => MockHomeDataSourceImpl();

// Repository Provider
@riverpod
HomeRepository homeRepository(Ref ref) =>
    HomeRepositoryImpl(dataSource: ref.watch(homeDataSourceProvider));

// UseCase Providers
@riverpod
GetNoticesUseCase getNoticesUseCase(Ref ref) =>
    GetNoticesUseCase(repository: ref.watch(homeRepositoryProvider));

@riverpod
GetPopularPostsUseCase getPopularPostsUseCase(Ref ref) =>
    GetPopularPostsUseCase(repository: ref.watch(homeRepositoryProvider));

// 새로운 UseCase - 그룹 Repository를 주입받음
@riverpod
GetUserJoinedGroupsUseCase getUserJoinedGroupsUseCase(Ref ref) =>
    GetUserJoinedGroupsUseCase(
      groupRepository: ref.watch(groupRepositoryProvider),
    );

// 라우트 정의
final homeRoutes = [
  // 홈 화면 경로 등록
];
