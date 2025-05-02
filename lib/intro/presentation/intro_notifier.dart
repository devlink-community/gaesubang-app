import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/use_case/fetch_intro_data_use_case.dart';
import '../domain/use_case/fetch_intro_stats_use_case.dart';
import '../module/intro_di.dart';
import 'intro_action.dart';
import 'intro_state.dart';

final introNotifierProvider = StateNotifierProvider<IntroNotifier, AsyncValue<IntroState>>((ref) {
  return IntroNotifier(
    fetchIntroUserUseCase: ref.watch(fetchIntroUserUseCaseProvider),
    fetchIntroStatsUseCase: ref.watch(fetchIntroStatsUseCaseProvider),
  );
});

class IntroNotifier extends StateNotifier<AsyncValue<IntroState>> {
  final FetchIntroUserUseCase _fetchIntroUser;
  final FetchIntroStatsUseCase _fetchStats;

  IntroNotifier({
    required FetchIntroUserUseCase fetchIntroUserUseCase,
    required FetchIntroStatsUseCase fetchIntroStatsUseCase,
  })  : _fetchIntroUser = fetchIntroUserUseCase,
        _fetchStats = fetchIntroStatsUseCase,
        super(const AsyncLoading()) {
    _init();
  }

  Future<void> _init() async {
    final userAsync = await _fetchIntroUser.execute();
    final statsAsync = await _fetchStats.execute();

    state = AsyncData(IntroState(userProfile: userAsync, focusStats: statsAsync));
  }

  /// 모든 사용자 액션은 여기로 집약
  Future<void> onAction(IntroAction action) async {
    switch (action) {
      case OpenSettings():
        // 화면 이동은 ScreenRoot에서 처리
        break;

      case RefreshIntro():
        // 새로고침: loading으로 상태 초기화 후 재호출
        state = const AsyncLoading();
        final userAsync = await _fetchIntroUser.execute();
        final statsAsync = await _fetchStats.execute();
        state = AsyncData(IntroState(
          userProfile: userAsync,
          focusStats: statsAsync,
        ));
        break;
    }
  }
}
