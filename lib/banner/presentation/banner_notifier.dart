import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/usecase/get_active_banners_use_case.dart';
import '../module/banner_di.dart';
import 'banner_action.dart';
import 'banner_state.dart';

part 'banner_notifier.g.dart';

@riverpod
class BannerNotifier extends _$BannerNotifier {
  late final GetActiveBannersUseCase _getActiveBannersUseCase;

  @override
  BannerState build() {
    _getActiveBannersUseCase = ref.watch(getActiveBannersUseCaseProvider);

    // 빌드 후 자동으로 배너 로드 시작
    Future.microtask(() => _loadActiveBanner());

    return const BannerState();
  }

  Future<void> onAction(BannerAction action) async {
    switch (action) {
      case LoadBanners():
        await _loadActiveBanner();
        break;
      case RefreshBanners():
        await _refreshBanner();
        break;
      case OnTapBanner(:final bannerId, :final linkUrl):
        _handleBannerTap(bannerId, linkUrl);
        break;
    }
  }

  Future<void> _loadActiveBanner() async {
    state = state.copyWith(activeBanner: const AsyncLoading());

    final result = await _getActiveBannersUseCase.execute();

    state = state.copyWith(
      activeBanner: result,
      lastUpdated: DateTime.now(),
    );
  }

  Future<void> _refreshBanner() async {
    // 새로고침 시에도 로딩 상태 표시
    await _loadActiveBanner();
  }

  void _handleBannerTap(String bannerId, String? linkUrl) {
    // 현재는 아무 동작 없음 (요구사항)
    // 추후 외부 링크 이동 기능 구현 시 이곳에서 처리
    // 예: if (linkUrl != null) launchUrl(Uri.parse(linkUrl));

    // 디버그 로그만 출력
    print('배너 클릭됨 - ID: $bannerId, URL: $linkUrl');
  }
}