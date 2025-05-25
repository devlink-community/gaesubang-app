import 'package:devlink_mobile_app/auth/domain/usecase/core/get_current_user_use_case.dart';
import 'package:devlink_mobile_app/banner/domain/usecase/get_active_banners_use_case.dart';
import 'package:devlink_mobile_app/banner/module/banner_di.dart';
import 'package:devlink_mobile_app/home/domain/usecase/get_joined_group_use_case.dart';
import 'package:devlink_mobile_app/home/domain/usecase/get_popular_posts_use_case.dart';
import 'package:devlink_mobile_app/home/module/home_di.dart';
import 'package:devlink_mobile_app/home/presentation/home_action.dart';
import 'package:devlink_mobile_app/home/presentation/home_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_notifier.g.dart';

@riverpod
class HomeNotifier extends _$HomeNotifier {
  // late final GetNoticesUseCase _getNoticesUseCase;
  late final GetPopularPostsUseCase _getPopularPostsUseCase;
  late final GetActiveBannersUseCase _getActiveBannersUseCase;
  late final GetJoinedGroupUseCase _getJoinedGroupUseCase;
  late final GetCurrentUserUseCase _getCurrentUserUseCase;

  @override
  HomeState build() {
    // _getNoticesUseCase = ref.watch(getNoticesUseCaseProvider);
    _getPopularPostsUseCase = ref.watch(getPopularPostsUseCaseProvider);
    _getActiveBannersUseCase = ref.watch(getActiveBannersUseCaseProvider);
    _getJoinedGroupUseCase = ref.watch(getJoinedGroupUseCaseProvider);
    _getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);

    // ref.onDispose 이전에 로딩 시작 (빌드 후 바로 로딩 시작)
    Future.microtask(() => _loadInitialData());

    return const HomeState();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadPopularPosts(),
      _loadActiveBanner(),
      _loadJoinedGroups(),
      _loadCurrentMember(),
    ]);
  }

  Future<void> _loadPopularPosts() async {
    state = state.copyWith(popularPosts: const AsyncLoading());
    final result = await _getPopularPostsUseCase.execute();
    state = state.copyWith(popularPosts: result);
  }

  Future<void> _loadActiveBanner() async {
    state = state.copyWith(activeBanner: const AsyncLoading());
    final result = await _getActiveBannersUseCase.execute();
    state = state.copyWith(activeBanner: result);
  }

  Future<void> _loadJoinedGroups() async {
    state = state.copyWith(joinedGroups: const AsyncLoading());
    final result = await _getJoinedGroupUseCase.execute();
    state = state.copyWith(joinedGroups: result);
  }

  Future<void> _loadCurrentMember() async {
    state = state.copyWith(currentMember: const AsyncLoading());
    final result = await _getCurrentUserUseCase.execute();
    state = state.copyWith(
      currentMember: result,
      // 사용자 정보에서 직접 Summary 데이터 추출
      totalStudyTimeMinutes: result.when(
        data: (user) => AsyncData(user.summary?.allTimeTotalSeconds ?? 0 ~/ 60),
        loading: () => const AsyncLoading(),
        error: (error, stack) => AsyncError(error, stack),
      ),
      streakDays: result.when(
        data: (user) => AsyncData(user.summary?.currentStreakDays ?? 0),
        loading: () => const AsyncLoading(),
        error: (error, stack) => AsyncError(error, stack),
      ),
    );
  }

  Future<void> onAction(HomeAction action) async {
    switch (action) {
      case RefreshHome():
        await _loadInitialData();
        break;

      case OnTapGroup _:
      case OnTapPopularPost _:
      case OnTapSettings _:
      case OnTapNotification _:
      case OnTapCreateGroup _:
        break;
    }
  }
}
