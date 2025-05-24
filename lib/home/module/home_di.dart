import 'package:devlink_mobile_app/auth/domain/usecase/get_current_user_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/community/module/community_di.dart';
import 'package:devlink_mobile_app/banner/module/banner_di.dart';
import 'package:devlink_mobile_app/group/module/group_di.dart';
import 'package:devlink_mobile_app/home/domain/usecase/get_joined_group_use_case.dart';
import 'package:devlink_mobile_app/home/domain/usecase/get_streak_days_use_case.dart';
import 'package:devlink_mobile_app/home/domain/usecase/get_total_study_times_use_case.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/data_source/home_data_source.dart';
import '../data/data_source/mock_home_data_source_impl.dart';
import '../data/repository_impl/home_repository_impl.dart';
import '../domain/repository/home_repository.dart';
import '../domain/usecase/get_notices_use_case.dart';
import '../domain/usecase/get_popular_posts_use_case.dart';

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
    GetPopularPostsUseCase(postRepository: ref.watch(postRepositoryProvider));

@riverpod
GetTotalStudyTimesUseCase getTotalStudyTimesUseCase(Ref ref) =>
    GetTotalStudyTimesUseCase(
      groupRepository: ref.watch(groupRepositoryProvider),
    );

@riverpod
GetJoinedGroupUseCase getJoinedGroupUseCase(Ref ref) =>
    GetJoinedGroupUseCase(groupRepository: ref.watch(groupRepositoryProvider));

@riverpod
GetStreakDaysUseCase getStreakDaysUseCase(Ref ref) =>
    GetStreakDaysUseCase(groupRepository: ref.watch(groupRepositoryProvider));

@riverpod
GetCurrentUserUseCase getCurrentUserUseCase(Ref ref) =>
    GetCurrentUserUseCase(repository: ref.watch(authRepositoryProvider));
// 라우트 정의
final homeRoutes = [
  // 홈 화면 경로 등록
];
