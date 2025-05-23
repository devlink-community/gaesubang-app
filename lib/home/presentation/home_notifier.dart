import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/group/data/mapper/group_mapper.dart';
import 'package:devlink_mobile_app/home/domain/usecase/get_notices_use_case.dart';
import 'package:devlink_mobile_app/home/domain/usecase/get_popular_posts_use_case.dart';
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

  @override
  HomeState build() {
    AppLogger.ui('HomeNotifier 초기화 시작');

    _getNoticesUseCase = ref.watch(getNoticesUseCaseProvider);
    _getPopularPostsUseCase = ref.watch(getPopularPostsUseCaseProvider);
    _getActiveBannersUseCase = ref.watch(getActiveBannersUseCaseProvider);

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
    AppLogger.logBanner('홈 화면 초기 데이터 로드 시작');
    final startTime = DateTime.now();

    AppLogger.logStep(1, 2, '병렬 데이터 로드 시작');
    AppLogger.logState('홈 데이터 로드 계획', {
      'load_type': 'parallel',
      'data_types': [
        'notices',
        'user_groups',
        'popular_posts',
        'active_banner',
      ],
      'concurrent_requests': 4,
    });

    try {
      // 병렬 처리로 모든 데이터 로드
      await Future.wait([
        _loadNotices(),
        _loadUserGroups(),
        _loadPopularPosts(),
        _loadActiveBanner(),
      ]);

      AppLogger.logStep(2, 2, '병렬 데이터 로드 완료');
      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('홈 화면 초기 데이터 로드', duration);
      AppLogger.logBox(
        '홈 데이터 로드 완료',
        '병렬 처리 소요시간: ${duration.inMilliseconds}ms',
      );
    } catch (e, st) {
      AppLogger.error('홈 화면 초기 데이터 로드 실패', error: e, stackTrace: st);
    }
  }

  Future<void> _loadNotices() async {
    AppLogger.debug('공지사항 로드 시작');
    final startTime = DateTime.now();

    state = state.copyWith(notices: const AsyncLoading());
    final result = await _getNoticesUseCase.execute();

    switch (result) {
      case AsyncData(:final value):
        AppLogger.ui('공지사항 로드 성공: ${value.length}개');
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('공지사항 로드', duration);
      case AsyncError(:final error):
        AppLogger.error('공지사항 로드 실패', error: error);
      case AsyncLoading():
        AppLogger.debug('공지사항 로딩 중');
    }

    state = state.copyWith(notices: result);
  }

  Future<void> _loadUserGroups() async {
    AppLogger.debug('사용자 그룹 로드 시작');
    final startTime = DateTime.now();

    state = state.copyWith(userGroups: const AsyncLoading());

    // AuthProvider에서 현재 사용자 정보 가져오기
    final currentUser = ref.read(currentUserProvider);

    if (currentUser == null) {
      AppLogger.warning('현재 사용자 정보 없음 - 그룹 로드 불가');
      state = state.copyWith(
        userGroups: AsyncError('사용자 정보를 찾을 수 없습니다', StackTrace.current),
      );
      return;
    }

    AppLogger.logState('사용자 그룹 로드 정보', {
      'user_id': PrivacyMaskUtil.maskUserId(currentUser.uid),
      'nickname': PrivacyMaskUtil.maskNickname(currentUser.nickname),
      'joined_groups_count': currentUser.joinedGroups.length,
    });

    try {
      // 사용자의 joinedGroups 정보를 Group 목록으로 변환 (매퍼 사용)
      final groups = currentUser.joinedGroups.toGroupModelList();

      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('사용자 그룹 로드', duration);
      AppLogger.ui('사용자 그룹 로드 성공: ${groups.length}개');

      state = state.copyWith(userGroups: AsyncData(groups));
    } catch (e, stackTrace) {
      AppLogger.error('사용자 그룹 변환 실패', error: e, stackTrace: stackTrace);
      AppLogger.logState('그룹 변환 실패 상세', {
        'user_id': PrivacyMaskUtil.maskUserId(currentUser.uid),
        'joined_groups_raw_count': currentUser.joinedGroups.length,
        'error_type': e.runtimeType.toString(),
      });

      state = state.copyWith(userGroups: AsyncError(e, stackTrace));
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

  Future<void> onAction(HomeAction action) async {
    AppLogger.debug('홈 화면 액션 처리: ${action.runtimeType}');

    switch (action) {
      case RefreshHome():
        AppLogger.ui('홈 화면 수동 새로고침 요청');
        await _loadInitialData();
        break;

      // 이 액션들은 Root에서 처리 (네비게이션)
      case OnTapNotice(:final noticeId):
        AppLogger.ui('공지사항 탭: $noticeId (Root에서 네비게이션 처리)');
        break;

      case OnTapGroup(:final groupId):
        AppLogger.ui('그룹 탭: $groupId (Root에서 네비게이션 처리)');
        break;

      case OnTapPopularPost(:final postId):
        AppLogger.ui('인기 게시글 탭: $postId (Root에서 네비게이션 처리)');
        break;

      case OnTapSettings():
        AppLogger.ui('설정 탭 (Root에서 네비게이션 처리)');
        break;

      case OnTapNotification():
        AppLogger.ui('알림 탭 (Root에서 네비게이션 처리)');
        break;
    }
  }
}
