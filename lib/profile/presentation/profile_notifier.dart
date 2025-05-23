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

  /// 최적화된 데이터 로드 메서드 - 중복 요청 방지 로직 포함
  Future<void> loadData() async {
    try {
      debugPrint('🚀 ProfileNotifier: 최적화된 데이터 로드 시작 (단일 호출)');

      // 중복 요청 방지를 위한 요청 ID 생성
      final currentRequestId = DateTime.now().microsecondsSinceEpoch;
      debugPrint('🔄 ProfileNotifier: 요청 ID 생성: $currentRequestId');

      // 로딩 상태로 변경 + 요청 ID 저장
      state = state.copyWith(
        userProfile: const AsyncLoading(),
        focusStats: const AsyncLoading(),
        activeRequestId: currentRequestId,
      );

      // ✅ 단일 호출로 사용자 정보 + 통계 모두 로드
      final userProfileResult = await _getCurrentUserUseCase.execute();

      // 다른 요청이 이미 시작됐다면 무시
      if (state.activeRequestId != currentRequestId) {
        debugPrint(
          '⚠️ ProfileNotifier: 다른 요청이 진행 중이므로 현재 요청($currentRequestId) 무시',
        );
        return;
      }

      switch (userProfileResult) {
        case AsyncData(:final value):
          debugPrint('✅ ProfileNotifier: 사용자 프로필 로드 완료');

          // Member에 이미 포함된 focusStats 활용
          final focusStats = value.focusStats ?? _getDefaultStats();
          debugPrint('📊 최종 FocusStats:');
          debugPrint('  - totalMinutes: ${focusStats.totalMinutes}');
          debugPrint('  - weeklyMinutes: ${focusStats.weeklyMinutes}');

          // ✅ 데이터가 0이어도 정상적으로 AsyncData로 설정
          if (state.activeRequestId == currentRequestId) {
            state = state.copyWith(
              userProfile: userProfileResult,
              focusStats: AsyncData(focusStats), // 항상 AsyncData로 설정
              activeRequestId: null,
            );

            debugPrint(
              '✅ ProfileNotifier: 통계 데이터 설정 완료 (totalMinutes: ${focusStats.totalMinutes})',
            );
          } else {
            debugPrint(
              '⚠️ ProfileNotifier: 요청 완료 시점에 다른 요청이 진행 중이므로 상태 업데이트 무시',
            );
          }

        case AsyncError(:final error, :final stackTrace):
          debugPrint('❌ ProfileNotifier: 사용자 프로필 로드 실패 - $error');

          // 요청 ID가 여전히 유효한지 확인 후 에러 상태 설정
          if (state.activeRequestId == currentRequestId) {
            state = state.copyWith(
              userProfile: userProfileResult,
              focusStats: AsyncError(error, stackTrace),
              activeRequestId: null, // 에러 발생 후 ID 초기화
            );
          }

        case AsyncLoading():
          // 이미 로딩 상태로 설정했으므로 별도 처리 불필요
          break;
      }
    } catch (e, st) {
      debugPrint('❌ ProfileNotifier: 데이터 로드 중 예외 발생: $e');

      // 예외 발생 시에도 요청 ID 확인
      final currentRequestId = state.activeRequestId;
      if (currentRequestId != null) {
        state = state.copyWith(
          userProfile: AsyncValue.error(e, st),
          focusStats: AsyncValue.error(e, st),
          activeRequestId: null, // 예외 발생 후 ID 초기화
        );
      }
    }
  }

  /// 기본 통계 반환 (데이터가 없을 때 사용)
  FocusTimeStats _getDefaultStats() {
    debugPrint('🔧 ProfileNotifier: 기본(빈) 통계 생성 중');
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
