import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/group/data/mapper/group_mapper.dart';
import 'package:devlink_mobile_app/home/domain/usecase/get_notices_use_case.dart';
import 'package:devlink_mobile_app/home/domain/usecase/get_popular_posts_use_case.dart';
import 'package:devlink_mobile_app/home/module/home_di.dart';
import 'package:devlink_mobile_app/banner/domain/usecase/get_active_banners_use_case.dart';
import 'package:devlink_mobile_app/banner/module/banner_di.dart';
import 'package:devlink_mobile_app/home/presentation/home_action.dart';
import 'package:devlink_mobile_app/home/presentation/home_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_notifier.g.dart';

@riverpod
class HomeNotifier extends _$HomeNotifier {
  late final GetNoticesUseCase _getNoticesUseCase;
  late final GetPopularPostsUseCase _getPopularPostsUseCase;
  late final GetActiveBannersUseCase _getActiveBannersUseCase;

  @override
  HomeState build() {
    _getNoticesUseCase = ref.watch(getNoticesUseCaseProvider);
    _getPopularPostsUseCase = ref.watch(getPopularPostsUseCaseProvider);
    _getActiveBannersUseCase = ref.watch(getActiveBannersUseCaseProvider);

    // ref.onDispose 이전에 로딩 시작 (빌드 후 바로 로딩 시작)
    Future.microtask(() => _loadInitialData());

    return const HomeState();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadNotices(),
      _loadUserGroups(),
      _loadPopularPosts(),
      _loadActiveBanner(),
    ]);
  }

  Future<void> _loadNotices() async {
    state = state.copyWith(notices: const AsyncLoading());
    final result = await _getNoticesUseCase.execute();
    state = state.copyWith(notices: result);
  }

  Future<void> _loadUserGroups() async {
    state = state.copyWith(userGroups: const AsyncLoading());

    // AuthProvider에서 현재 사용자 정보 가져오기
    final currentUser = ref.read(currentUserProvider);

    if (currentUser == null) {
      state = state.copyWith(
        userGroups: AsyncError('사용자 정보를 찾을 수 없습니다', StackTrace.current),
      );
      return;
    }

    try {
      // 사용자의 joinedGroups 정보를 Group 목록으로 변환 (매퍼 사용)
      final groups = currentUser.joinedGroups.toGroupModelList();
      state = state.copyWith(userGroups: AsyncData(groups));
    } catch (e, stackTrace) {
      state = state.copyWith(userGroups: AsyncError(e, stackTrace));
    }
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

  Future<void> onAction(HomeAction action) async {
    switch (action) {
      case RefreshHome():
        await _loadInitialData();
        break;

    // 이 액션들은 Root에서 처리 (네비게이션)
      case OnTapNotice _:
      case OnTapGroup _:
      case OnTapPopularPost _:
      case OnTapSettings _:
      case OnTapNotification _:
        break;
    }
  }
}