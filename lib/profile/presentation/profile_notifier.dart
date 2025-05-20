import 'package:flutter/cupertino.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/domain/usecase/get_current_user_use_case.dart';
import '../../auth/module/auth_di.dart';
import '../domain/model/focus_time_stats.dart';
import 'profile_action.dart';
import 'profile_refresh_state.dart';
import 'profile_state.dart';

part 'profile_notifier.g.dart';

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  late final GetCurrentUserUseCase _getCurrentUserUseCase;

  @override
  ProfileState build() {
    // ✅ 단일 UseCase만 초기화
    _getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);

    // ✅ 갱신 상태는 listen으로 처리
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

  /// 최적화된 데이터 로드 메서드 - 단일 API 호출로 프로필 + 통계 동시 로드
  Future<void> loadData() async {
    try {
      debugPrint('🚀 ProfileNotifier: 최적화된 데이터 로드 시작 (단일 호출)');

      // 로딩 상태로 변경
      state = state.copyWith(
        userProfile: const AsyncLoading(),
        focusStats: const AsyncLoading(),
      );

      // ✅ 단일 호출로 사용자 정보 + 통계 모두 로드
      final userProfileResult = await _getCurrentUserUseCase.execute();

      switch (userProfileResult) {
        case AsyncData(:final value):
          debugPrint('✅ ProfileNotifier: 사용자 프로필 로드 완료');

          // Member에 이미 포함된 focusStats 활용
          final focusStats = value.focusStats ?? _getDefaultStats();

          // 최종 상태 업데이트 - 단일 호출로 두 상태 모두 업데이트
          state = state.copyWith(
            userProfile: userProfileResult,
            focusStats: AsyncData(focusStats),
          );

          debugPrint('✅ ProfileNotifier: 모든 데이터 로드 완료 (최적화됨)');

        case AsyncError(:final error, :final stackTrace):
          debugPrint('❌ ProfileNotifier: 사용자 프로필 로드 실패 - $error');

          // 에러 시 두 상태 모두 에러로 설정
          state = state.copyWith(
            userProfile: userProfileResult,
            focusStats: AsyncError(error, stackTrace),
          );

        case AsyncLoading():
          // 이미 로딩 상태로 설정했으므로 별도 처리 불필요
          break;
      }
    } catch (e, st) {
      debugPrint('❌ ProfileNotifier: 데이터 로드 중 예외 발생: $e');
      // 예외 발생 시 두 상태 모두 에러로 설정
      state = state.copyWith(
        userProfile: AsyncValue.error(e, st),
        focusStats: AsyncValue.error(e, st),
      );
    }
  }

  /// 기본 통계 반환 (데이터가 없을 때 사용)
  FocusTimeStats _getDefaultStats() {
    return const FocusTimeStats(
      totalMinutes: 0,
      weeklyMinutes: {'월': 0, '화': 0, '수': 0, '목': 0, '금': 0, '토': 0, '일': 0},
    );
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

  /// 명시적 새로고침 메서드 (외부에서 직접 호출 가능)
  Future<void> refresh() async {
    debugPrint('🔄 ProfileNotifier: 명시적 새로고침 호출');
    await loadData();
  }
}
