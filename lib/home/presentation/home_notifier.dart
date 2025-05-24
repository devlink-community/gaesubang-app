import 'package:devlink_mobile_app/auth/domain/usecase/get_current_user_use_case.dart';
import 'package:devlink_mobile_app/home/domain/usecase/get_joined_group_use_case.dart';
import 'package:devlink_mobile_app/home/domain/usecase/get_notices_use_case.dart';
import 'package:devlink_mobile_app/home/domain/usecase/get_popular_posts_use_case.dart';
import 'package:devlink_mobile_app/home/domain/usecase/get_streak_days_use_case.dart';
import 'package:devlink_mobile_app/home/domain/usecase/get_total_study_times_use_case.dart';
import 'package:devlink_mobile_app/home/module/home_di.dart';
import 'package:devlink_mobile_app/banner/domain/usecase/get_active_banners_use_case.dart';
import 'package:devlink_mobile_app/banner/module/banner_di.dart';
import 'package:devlink_mobile_app/home/presentation/home_action.dart';
import 'package:devlink_mobile_app/home/presentation/home_state.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/privacy_mask_util.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_notifier.g.dart';

@riverpod
class HomeNotifier extends _$HomeNotifier {
  late final GetNoticesUseCase _getNoticesUseCase;
  late final GetPopularPostsUseCase _getPopularPostsUseCase;
  late final GetActiveBannersUseCase _getActiveBannersUseCase;
  late final GetTotalStudyTimesUseCase _getTotalStudyTimesUseCase;
  late final GetJoinedGroupUseCase _getJoinedGroupUseCase;
  late final GetStreakDaysUseCase _getStreakDaysUseCase;
  late final GetCurrentUserUseCase _getCurrentUserUseCase;

  @override
  HomeState build() {
    AppLogger.ui('HomeNotifier 초기화 시작');

    _getNoticesUseCase = ref.watch(getNoticesUseCaseProvider);
    _getPopularPostsUseCase = ref.watch(getPopularPostsUseCaseProvider);
    _getActiveBannersUseCase = ref.watch(getActiveBannersUseCaseProvider);
    _getTotalStudyTimesUseCase = ref.watch(getTotalStudyTimesUseCaseProvider);
    _getJoinedGroupUseCase = ref.watch(getJoinedGroupUseCaseProvider);
    _getStreakDaysUseCase = ref.watch(getStreakDaysUseCaseProvider);
    _getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);

    AppLogger.logState('홈 화면 UseCase 초기화', {
      'notices_usecase': 'initialized',
      'popular_posts_usecase': 'initialized',
      'active_banners_usecase': 'initialized',
    });

    // ref.onDispose 이전에 로딩 시작 (빌드 후 바로 로딩 시작)
    Future.microtask(() => _loadInitialData());

    AppLogger.ui('HomeNotifier 초기화 완료 - 초기 데이터 로드 예약됨');
    return const HomeState();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadPopularPosts(),
      _loadActiveBanner(),
      _loadTotalStudyTime(),
      _loadStreakDays(),
      _loadJoinedGroups(),
      _loadCurrentMember(),
    ]);
  }

  Future<void> _loadUserGroups() async {
    state = state.copyWith(joinedGroups: const AsyncLoading());

    AppLogger.logState('사용자 그룹 로드 정보', {
      'user_id': PrivacyMaskUtil.maskUserId(currentUser.uid),
      'nickname': PrivacyMaskUtil.maskNickname(currentUser.nickname),
      'joined_groups_count': currentUser.joinedGroups.length,
    });

    try {
      // 사용자의 joinedGroups 정보를 Group 목록으로 변환 (매퍼 사용)
      final groups = await _getJoinedGroupUseCase.execute();
      state = state.copyWith(joinedGroups: groups);
    } catch (e, stackTrace) {
      state = state.copyWith(joinedGroups: AsyncError(e, stackTrace));
    }
  }

  Future<void> _loadPopularPosts() async {
    AppLogger.debug('인기 게시글 로드 시작');
    final startTime = DateTime.now();

    state = state.copyWith(popularPosts: const AsyncLoading());
    final result = await _getPopularPostsUseCase.execute();

    switch (result) {
      case AsyncData(:final value):
        AppLogger.ui('인기 게시글 로드 성공: ${value.length}개');
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('인기 게시글 로드', duration);
      case AsyncError(:final error):
        AppLogger.error('인기 게시글 로드 실패', error: error);
      case AsyncLoading():
        AppLogger.debug('인기 게시글 로딩 중');
    }

    state = state.copyWith(popularPosts: result);
  }

  Future<void> _loadActiveBanner() async {
    AppLogger.debug('활성 배너 로드 시작');
    final startTime = DateTime.now();

    state = state.copyWith(activeBanner: const AsyncLoading());
    final result = await _getActiveBannersUseCase.execute();

    switch (result) {
      case AsyncData(:final value):
        if (value != null) {
          AppLogger.ui('활성 배너 로드 성공: 1개');
          final duration = DateTime.now().difference(startTime);
          AppLogger.logPerformance('활성 배너 로드', duration);

          AppLogger.logState('로드된 배너 정보', {
            'banner_id': value.id,
            'has_link_url': value.linkUrl != null,
            'is_active': value.isActive,
            'display_order': value.displayOrder,
          });
        } else {
          AppLogger.ui('활성 배너 없음');
          final duration = DateTime.now().difference(startTime);
          AppLogger.logPerformance('활성 배너 로드', duration);
        }
      case AsyncError(:final error):
        AppLogger.error('활성 배너 로드 실패', error: error);
      case AsyncLoading():
        AppLogger.debug('활성 배너 로딩 중');
    }

    state = state.copyWith(activeBanner: result);
  }

  Future<void> _loadTotalStudyTime() async {
    state = state.copyWith(totalStudyTimeMinutes: const AsyncLoading());
    final result = await _getTotalStudyTimesUseCase.execute();
    state = state.copyWith(totalStudyTimeMinutes: result);
  }

  Future<void> _loadStreakDays() async {
    state = state.copyWith(streakDays: const AsyncLoading());
    final result = await _getStreakDaysUseCase.execute();
    state = state.copyWith(streakDays: result);
  }

  Future<void> _loadJoinedGroups() async {
    state = state.copyWith(joinedGroups: const AsyncLoading());
    final result = await _getJoinedGroupUseCase.execute();
    state = state.copyWith(joinedGroups: result);
  }

  Future<void> _loadCurrentMember() async {
    state = state.copyWith(currentMember: const AsyncLoading());
    final result = await _getCurrentUserUseCase.execute();
    state = state.copyWith(currentMember: result);
  }

  Future<void> onAction(HomeAction action) async {
    AppLogger.debug('홈 화면 액션 처리: ${action.runtimeType}');

    switch (action) {
      case RefreshHome():
        AppLogger.ui('홈 화면 수동 새로고침 요청');
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
