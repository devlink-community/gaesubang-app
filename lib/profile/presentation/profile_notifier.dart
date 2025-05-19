import 'package:flutter/cupertino.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/domain/model/member.dart';
import '../../auth/domain/usecase/get_current_user_use_case.dart';
import '../../auth/domain/usecase/get_focus_stats_use_case.dart';
import '../../auth/module/auth_di.dart';
import '../domain/model/focus_time_stats.dart';
import 'profile_action.dart';
import 'profile_state.dart';

part 'profile_notifier.g.dart';

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  late final GetCurrentUserUseCase _getCurrentUserUseCase;
  late final GetFocusStatsUseCase _getFocusStatsUseCase;

  @override
  ProfileState build() {
    _getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);
    _getFocusStatsUseCase = ref.watch(getFocusStatsUseCaseProvider);

    // 초기화 직후 데이터 로드 시작
    _loadData();

    return const ProfileState();
  }

  // 데이터 로드 메서드
  Future<void> _loadData() async {
    try {
      // 로딩 상태로 변경
      state = state.copyWith(
        userProfile: const AsyncLoading(),
        focusStats: const AsyncLoading(),
      );

      // 프로필 로드
      late AsyncValue<Member> userProfileResult;
      try {
        userProfileResult = await _getCurrentUserUseCase.execute();
      } catch (e, st) {
        userProfileResult = AsyncValue.error(e, st);
      }

      // 통계 로드 (실제 UseCase 사용)
      late AsyncValue<FocusTimeStats> focusStatsResult;
      try {
        // 현재 사용자의 ID 가져오기
        if (userProfileResult is AsyncData<Member>) {
          final userId = userProfileResult.value!.id;
          focusStatsResult = await _getFocusStatsUseCase.execute(userId);
        } else {
          // 사용자 정보를 가져올 수 없는 경우 에러 처리
          focusStatsResult = const AsyncValue.error(
            'Failed to load user profile for stats',
            StackTrace.empty,
          );
        }
      } catch (e, st) {
        focusStatsResult = AsyncValue.error(e, st);
      }

      // 최종 상태 생성
      state = state.copyWith(
        userProfile: userProfileResult,
        focusStats: focusStatsResult,
      );
    } catch (e, st) {
      debugPrint('데이터 로드 중 오류 발생: $e');
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
