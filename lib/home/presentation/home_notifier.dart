import 'package:devlink_mobile_app/home/domain/usecase/get_notices_use_case.dart';
import 'package:devlink_mobile_app/home/domain/usecase/get_popular_posts_use_case.dart';
import 'package:devlink_mobile_app/home/domain/usecase/get_user_joined_groups_use_case.dart';
import 'package:devlink_mobile_app/home/module/home_di.dart';
import 'package:devlink_mobile_app/home/presentation/home_action.dart';
import 'package:devlink_mobile_app/home/presentation/home_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_notifier.g.dart';

@riverpod
class HomeNotifier extends _$HomeNotifier {
  late final GetNoticesUseCase _getNoticesUseCase;
  late final GetUserJoinedGroupsUseCase _getUserJoinedGroupsUseCase;
  late final GetPopularPostsUseCase _getPopularPostsUseCase;

  @override
  HomeState build() {
    _getNoticesUseCase = ref.watch(getNoticesUseCaseProvider);
    _getUserJoinedGroupsUseCase = ref.watch(getUserJoinedGroupsUseCaseProvider);
    _getPopularPostsUseCase = ref.watch(getPopularPostsUseCaseProvider);

    // ref.onDispose 이전에 로딩 시작 (빌드 후 바로 로딩 시작)
    Future.microtask(() => _loadInitialData());

    return const HomeState();
  }

  Future<void> _loadInitialData() async {
    await _loadNotices();
    await _loadUserGroups();
    await _loadPopularPosts();
  }

  Future<void> _loadNotices() async {
    state = state.copyWith(notices: const AsyncLoading());
    final result = await _getNoticesUseCase.execute();
    state = state.copyWith(notices: result);
  }

  Future<void> _loadUserGroups() async {
    state = state.copyWith(userGroups: const AsyncLoading());
    // 현재 로그인한 사용자 ID (임시로 하드코딩)
    // TODO: 실제 구현에서는 AuthRepository에서 현재 사용자 ID를 가져와야 함
    const String currentUserId = 'user1';
    final result = await _getUserJoinedGroupsUseCase.execute(currentUserId);
    state = state.copyWith(userGroups: result);
  }

  Future<void> _loadPopularPosts() async {
    state = state.copyWith(popularPosts: const AsyncLoading());
    final result = await _getPopularPostsUseCase.execute();
    state = state.copyWith(popularPosts: result);
  }

  Future<void> onAction(HomeAction action) async {
    switch (action) {
      case RefreshHome():
        await _loadInitialData();

      // 이 액션들은 Root에서 처리 (네비게이션)
      case OnTapNotice():
      case OnTapGroup():
      case OnTapPopularPost():
      case OnTapSettings():
      case OnTapNotification():
        break;
    }
  }
}
