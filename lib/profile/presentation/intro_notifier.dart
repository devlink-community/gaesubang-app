import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/model/member.dart';
import '../domain/model/focus_time_stats.dart';
import '../domain/use_case/fetch_intro_data_use_case.dart';
import '../domain/use_case/fetch_intro_stats_use_case.dart';
import '../module/intro_di.dart';
import 'intro_action.dart';
import 'intro_state.dart';

final introNotifierProvider =
    StateNotifierProvider<IntroNotifier, AsyncValue<IntroState>>(
      (ref) => IntroNotifier(
        fetchUserUseCase: ref.watch(fetchIntroUserUseCaseProvider),
        fetchStatsUseCase: ref.watch(fetchIntroStatsUseCaseProvider),
      ),
    );

/// 2) 일반 StateNotifier로 구현
class IntroNotifier extends StateNotifier<AsyncValue<IntroState>> {
  // UseCase들을 final로 선언하고 생성자에서 주입받음
  final FetchIntroUserUseCase fetchUserUseCase;
  final FetchIntroStatsUseCase fetchStatsUseCase;

  IntroNotifier({
    required this.fetchUserUseCase,
    required this.fetchStatsUseCase,
  }) : super(const AsyncValue.loading()) {
    // 초기화 직후 데이터 로드 시작
    _loadData();
  }

  // 데이터 로드 메서드
  Future<void> _loadData() async {
    try {
      // 로딩 상태로 변경
      state = const AsyncValue.loading();

      // 2-1) AsyncValue 초기화
      late AsyncValue<Member> userProfileResult;
      late AsyncValue<FocusTimeStats> focusStatsResult;

      // 2-2) 프로필 로드
      try {
        userProfileResult = await fetchUserUseCase.execute();
      } catch (e, st) {
        userProfileResult = AsyncValue.error(e, st);
      }

      // 2-3) 통계 로드
      try {
        focusStatsResult = await fetchStatsUseCase.execute();
      } catch (e, st) {
        focusStatsResult = AsyncValue.error(e, st);
      }

      // 2-4) 최종 상태 생성
      final newState = IntroState(
        userProfile: userProfileResult,
        focusStats: focusStatsResult,
      );

      // 2-5) 상태 업데이트
      state = AsyncValue.data(newState);
    } catch (e, st) {
      debugPrint('데이터 로드 중 오류 발생: $e');
      // 오류 발생 시 에러 상태로 변경
      state = AsyncValue.error(e, st);
    }
  }

  /// 3) 화면 액션 처리
  Future<void> onAction(IntroAction action) async {
    switch (action) {
      case OpenSettings():
        // 네비게이션은 UI 쪽에서 처리
        break;
      case RefreshIntro():
        // 전체 다시 로드
        await _loadData();
        break;
    }
  }

  // 명시적 새로고침 메서드 추가 (외부에서 직접 호출 가능)
  Future<void> refresh() async {
    await _loadData();
  }
}
