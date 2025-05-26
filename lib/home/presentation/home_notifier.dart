import 'package:devlink_mobile_app/auth/domain/usecase/core/get_current_user_use_case.dart';
import 'package:devlink_mobile_app/banner/domain/usecase/get_active_banners_use_case.dart';
import 'package:devlink_mobile_app/banner/module/banner_di.dart';
import 'package:devlink_mobile_app/core/auth/auth_state.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/home/domain/usecase/get_joined_group_use_case.dart';
import 'package:devlink_mobile_app/home/domain/usecase/get_popular_posts_use_case.dart';
import 'package:devlink_mobile_app/home/module/home_di.dart';
import 'package:devlink_mobile_app/home/presentation/home_action.dart';
import 'package:devlink_mobile_app/home/presentation/home_state.dart';
import 'package:devlink_mobile_app/notification/domain/usecase/get_notifications_use_case.dart'; // 🆕 추가
import 'package:devlink_mobile_app/notification/module/notification_di.dart'; // 🆕 추가
import 'package:devlink_mobile_app/core/auth/auth_provider.dart'; // 🆕 추가
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_notifier.g.dart';

@riverpod
class HomeNotifier extends _$HomeNotifier {
  // late final GetNoticesUseCase _getNoticesUseCase;
  late final GetPopularPostsUseCase _getPopularPostsUseCase;
  late final GetActiveBannersUseCase _getActiveBannersUseCase;
  late final GetJoinedGroupUseCase _getJoinedGroupUseCase;
  late final GetCurrentUserUseCase _getCurrentUserUseCase;
  late final GetNotificationsUseCase _getNotificationsUseCase; // 🆕 추가

  @override
  HomeState build() {
    // _getNoticesUseCase = ref.watch(getNoticesUseCaseProvider);
    _getPopularPostsUseCase = ref.watch(getPopularPostsUseCaseProvider);
    _getActiveBannersUseCase = ref.watch(getActiveBannersUseCaseProvider);
    _getJoinedGroupUseCase = ref.watch(getJoinedGroupUseCaseProvider);
    _getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);
    _getNotificationsUseCase = ref.watch(
      getNotificationsUseCaseProvider,
    ); // 🆕 추가

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
      _loadUnreadNotificationCount(), // 🆕 추가
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
      totalStudyTimeMinutes: result.when(
        data: (user) {
          final seconds = user.summary?.allTimeTotalSeconds ?? 0;
          final minutes = seconds ~/ 60;
          AppLogger.debug('Study Time: $seconds초 → $minutes분');
          return AsyncData(minutes); // 분 단위로 저장
        },
        loading: () => const AsyncLoading(),
        error: (error, stack) => AsyncError(error, stack),
      ),
      streakDays: result.when(
        data: (user) {
          // streak 값 가져오기
          final streak = user.summary?.currentStreakDays ?? 0;
          AppLogger.debug('연속 출석일: $streak일');
          return AsyncData(streak);
        },
        loading: () => const AsyncLoading(),
        error: (error, stack) => AsyncError(error, stack),
      ),
    );
  }

  // 🆕 읽지 않은 알림 수 로딩 메서드 추가
  Future<void> _loadUnreadNotificationCount() async {
    AppLogger.info('읽지 않은 알림 수 로딩 시작', tag: 'HomeNotifier');

    state = state.copyWith(unreadNotificationCount: const AsyncLoading());

    try {
      // 현재 사용자 ID 가져오기
      final authStateAsync = ref.read(authStateProvider);
      final currentUserId = authStateAsync.when(
        data: (authState) {
          switch (authState) {
            case Authenticated(user: final member):
              return member.uid;
            case _:
              return null;
          }
        },
        loading: () => null,
        error: (error, stackTrace) => null,
      );

      if (currentUserId == null) {
        AppLogger.warning('사용자 ID가 null - 알림 수를 0으로 설정', tag: 'HomeNotifier');
        state = state.copyWith(unreadNotificationCount: const AsyncData(0));
        return;
      }

      AppLogger.debug('사용자 ID: $currentUserId로 알림 조회', tag: 'HomeNotifier');

      final result = await _getNotificationsUseCase.execute(currentUserId);

      result.when(
        data: (notifications) {
          final unreadCount = notifications.where((n) => !n.isRead).length;
          AppLogger.info('읽지 않은 알림 수: $unreadCount개', tag: 'HomeNotifier');
          state = state.copyWith(
            unreadNotificationCount: AsyncData(unreadCount),
          );
        },
        loading: () {
          state = state.copyWith(unreadNotificationCount: const AsyncLoading());
        },
        error: (error, stackTrace) {
          AppLogger.error(
            '알림 수 로딩 실패',
            tag: 'HomeNotifier',
            error: error,
            stackTrace: stackTrace,
          );
          // 에러 시 0으로 설정 (UI 깨짐 방지)
          state = state.copyWith(unreadNotificationCount: const AsyncData(0));
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '알림 수 로딩 예외',
        tag: 'HomeNotifier',
        error: e,
        stackTrace: stackTrace,
      );
      // 예외 시 0으로 설정 (UI 깨짐 방지)
      state = state.copyWith(unreadNotificationCount: const AsyncData(0));
    }
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
