import 'package:flutter/cupertino.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/domain/model/member.dart';
import '../../auth/domain/usecase/get_current_user_use_case.dart';
import '../../auth/domain/usecase/get_focus_stats_use_case.dart';
import '../../auth/module/auth_di.dart';
import '../domain/model/focus_time_stats.dart';
import 'profile_action.dart';
import 'profile_refresh_state.dart';
import 'profile_state.dart';

part 'profile_notifier.g.dart';

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  late final GetCurrentUserUseCase _getCurrentUserUseCase;
  late final GetFocusStatsUseCase _getFocusStatsUseCase;

  @override
  ProfileState build() {
    // ✅ late 필드 초기화는 한 번만 (build에서)
    _getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);
    _getFocusStatsUseCase = ref.watch(getFocusStatsUseCaseProvider);

    // ✅ 갱신 상태는 listen으로 처리 (watch가 아닌!)
    ref.listen(profileRefreshStateProvider, (previous, next) {
      if (next == true) {
        debugPrint('🔄 ProfileNotifier: 갱신 필요 감지, 데이터 로드 시작');
        Future.microtask(() async {
          await loadData();
          // 갱신 완료 후 상태 리셋
          ref.read(profileRefreshStateProvider.notifier).markRefreshed();
          debugPrint('✅ ProfileNotifier: 데이터 갱신 완료, 상태 리셋');
        });
      }
    });

    // build()에서는 초기 상태만 반환하고, 데이터 로드는 하지 않음
    return const ProfileState();
  }

  // 데이터 로드 메서드 - 외부에서 호출 가능하도록 public으로 변경
  Future<void> loadData() async {
    try {
      debugPrint('🚀 ProfileNotifier: 데이터 로드 시작');

      // 로딩 상태로 변경
      state = state.copyWith(
        userProfile: const AsyncLoading(),
        focusStats: const AsyncLoading(),
      );

      // 프로필 로드
      late AsyncValue<Member> userProfileResult;
      try {
        userProfileResult = await _getCurrentUserUseCase.execute();
        debugPrint('✅ ProfileNotifier: 사용자 프로필 로드 완료');
      } catch (e, st) {
        userProfileResult = AsyncValue.error(e, st);
        debugPrint('❌ ProfileNotifier: 사용자 프로필 로드 실패 - $e');
      }

      // 통계 로드 (실제 UseCase 사용)
      late AsyncValue<FocusTimeStats> focusStatsResult;
      try {
        // 현재 사용자의 ID 가져오기
        if (userProfileResult is AsyncData<Member>) {
          final userId = userProfileResult.value.id;
          focusStatsResult = await _getFocusStatsUseCase.execute(userId);
          debugPrint('✅ ProfileNotifier: 집중 통계 로드 완료');
        } else {
          // 사용자 정보를 가져올 수 없는 경우 에러 처리
          focusStatsResult = const AsyncValue.error(
            'Failed to load user profile for stats',
            StackTrace.empty,
          );
          debugPrint('❌ ProfileNotifier: 사용자 정보 없어 통계 로드 실패');
        }
      } catch (e, st) {
        focusStatsResult = AsyncValue.error(e, st);
        debugPrint('❌ ProfileNotifier: 집중 통계 로드 실패 - $e');
      }

      // 최종 상태 생성
      state = state.copyWith(
        userProfile: userProfileResult,
        focusStats: focusStatsResult,
      );

      debugPrint('✅ ProfileNotifier: 모든 데이터 로드 완료');
    } catch (e, st) {
      debugPrint('❌ ProfileNotifier: 데이터 로드 중 오류 발생: $e');
      // 오류 발생 시 에러 상태로 변경
      state = state.copyWith(
        userProfile: AsyncValue.error(e, st),
        focusStats: AsyncValue.error(e, st),
      );
    }
  }

  /// 화면 액션 처리
  Future<void> onAction(ProfileAction action) async {
    switch (action) {
      case OpenSettings():
        // 네비게이션은 UI 쪽에서 처리
        break;
      case RefreshProfile():
        debugPrint('🔄 ProfileNotifier: 수동 새로고침 요청');
        // 수동 새로고침도 갱신 상태를 통해 처리
        ref.read(profileRefreshStateProvider.notifier).markForRefresh();
        break;
    }
  }

  // 명시적 새로고침 메서드 추가 (외부에서 직접 호출 가능)
  Future<void> refresh() async {
    debugPrint('🔄 ProfileNotifier: 명시적 새로고침 호출');
    await loadData();
  }
}
