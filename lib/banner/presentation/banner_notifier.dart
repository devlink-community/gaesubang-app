import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/usecase/get_active_banners_use_case.dart';
import '../module/banner_di.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'banner_action.dart';
import 'banner_state.dart';

part 'banner_notifier.g.dart';

@riverpod
class BannerNotifier extends _$BannerNotifier {
  late final GetActiveBannersUseCase _getActiveBannersUseCase;

  @override
  BannerState build() {
    AppLogger.ui('BannerNotifier 초기화 시작');

    _getActiveBannersUseCase = ref.watch(getActiveBannersUseCaseProvider);

    AppLogger.logState('배너 UseCase 초기화', {
      'active_banners_usecase': 'initialized',
    });

    // 빌드 후 자동으로 배너 로드 시작
    Future.microtask(() => _loadActiveBanner());

    AppLogger.ui('BannerNotifier 초기화 완료 - 배너 로드 예약됨');
    return const BannerState();
  }

  Future<void> onAction(BannerAction action) async {
    AppLogger.debug('배너 액션 처리: ${action.runtimeType}');

    switch (action) {
      case LoadBanners():
        AppLogger.ui('배너 로드 액션 수신');
        await _loadActiveBanner();
        break;
      case RefreshBanners():
        AppLogger.ui('배너 새로고침 액션 수신');
        await _refreshBanner();
        break;
      case OnTapBanner(:final bannerId, :final linkUrl):
        AppLogger.ui('배너 탭 액션 수신');
        _handleBannerTap(bannerId, linkUrl);
        break;
    }
  }

  Future<void> _loadActiveBanner() async {
    AppLogger.logBanner('활성 배너 로드 시작');
    final startTime = DateTime.now();

    AppLogger.logStep(1, 2, '로딩 상태 설정');
    state = state.copyWith(activeBanner: const AsyncLoading());

    AppLogger.logStep(2, 2, '배너 데이터 조회');
    final result = await _getActiveBannersUseCase.execute();

    final duration = DateTime.now().difference(startTime);
    AppLogger.logPerformance('활성 배너 로드', duration);

    switch (result) {
      case AsyncData(:final value):
        if (value != null) {
          AppLogger.ui('활성 배너 로드 성공');
          AppLogger.logState('로드된 배너 정보', {
            'banner_id': value.id,
            'has_title': value.title.isNotEmpty,
            'has_link_url': value.linkUrl?.isNotEmpty ?? false,
            'is_active': value.isActive,
            'display_order': value.displayOrder,
            'has_image': value.imageUrl.isNotEmpty,
          });
          AppLogger.logBox(
            '배너 로드 완료',
            '배너 ID: ${value.id}\n소요시간: ${duration.inMilliseconds}ms',
          );
        } else {
          AppLogger.ui('활성 배너 없음');
          AppLogger.debug('현재 활성화된 배너가 없습니다');
        }
        break;
      case AsyncError(:final error):
        AppLogger.error('활성 배너 로드 실패', error: error);
        AppLogger.logState('배너 로드 실패 상세', {
          'error_type': error.runtimeType.toString(),
          'duration_ms': duration.inMilliseconds,
        });
        break;
      case AsyncLoading():
        AppLogger.debug('배너 로딩 중 (상태 유지)');
        break;
    }

    state = state.copyWith(
      activeBanner: result,
      lastUpdated: DateTime.now(),
    );
  }

  Future<void> _refreshBanner() async {
    AppLogger.ui('배너 새로고침 시작');

    // 새로고침 시에도 로딩 상태 표시
    await _loadActiveBanner();

    AppLogger.ui('배너 새로고침 완료');
  }

  void _handleBannerTap(String bannerId, String? linkUrl) {
    AppLogger.ui('배너 클릭 처리 시작');
    AppLogger.logState('배너 클릭 정보', {
      'banner_id': bannerId,
      'has_link_url': linkUrl != null,
      'link_url_length': linkUrl?.length ?? 0,
    });

    // 현재는 아무 동작 없음 (요구사항)
    // 추후 외부 링크 이동 기능 구현 시 이곳에서 처리
    // 예: if (linkUrl != null) launchUrl(Uri.parse(linkUrl));

    AppLogger.debug('배너 클릭 처리 완료 - 현재는 디버그 로그만 출력');
    AppLogger.logState('배너 클릭 최종 처리', {
      'banner_id': bannerId,
      'link_url': linkUrl ?? 'null',
      'action_taken': 'debug_log_only',
      'future_feature': 'external_link_navigation',
    });
  }
}