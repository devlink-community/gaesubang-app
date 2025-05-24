import 'package:flutter/cupertino.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/domain/usecase/get_current_user_use_case.dart';
import '../../auth/module/auth_di.dart';
import '../domain/model/focus_time_stats.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/privacy_mask_util.dart';
import 'profile_action.dart';
import 'profile_refresh_state.dart';
import 'profile_state.dart';

part 'profile_notifier.g.dart';

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  late final GetCurrentUserUseCase _getCurrentUserUseCase;

  @override
  ProfileState build() {
    AppLogger.ui('ProfileNotifier 초기화 시작');

    // ✅ 단일 UseCase만 초기화
    _getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);

    // ✅ 갱신 상태는 listen으로 처리
    ref.listen(profileRefreshStateProvider, (previous, next) {
      if (next == true) {
        AppLogger.ui('프로필 갱신 필요 감지 - 데이터 로드 시작');
        Future.microtask(() async {
          await loadData();
          // 갱신 완료 후 상태 리셋
          ref.read(profileRefreshStateProvider.notifier).markRefreshed();
          AppLogger.ui('프로필 데이터 갱신 완료 - 상태 리셋');
        });
      }
    });

    AppLogger.ui('ProfileNotifier 초기화 완료');
    // build()에서는 초기 상태만 반환하고, 데이터 로드는 하지 않음
    return const ProfileState();
  }

  /// 최적화된 데이터 로드 메서드 - 중복 요청 방지 로직 포함
  Future<void> loadData() async {
    final startTime = DateTime.now();
    AppLogger.logBanner('프로필 데이터 로드 시작');

    try {
      // 중복 요청 방지를 위한 요청 ID 생성
      final currentRequestId = DateTime.now().microsecondsSinceEpoch;
      AppLogger.logState('프로필 로드 요청 정보', {
        'request_id': currentRequestId,
        'load_type': 'optimized_single_call',
      });

      AppLogger.logStep(1, 4, '로딩 상태 설정 및 요청 ID 저장');
      // 로딩 상태로 변경 + 요청 ID 저장
      state = state.copyWith(
        userProfile: const AsyncLoading(),
        focusStats: const AsyncLoading(),
        activeRequestId: currentRequestId,
      );

      AppLogger.logStep(2, 4, '사용자 정보 및 통계 단일 호출');
      // ✅ 단일 호출로 사용자 정보 + 통계 모두 로드
      final userProfileResult = await _getCurrentUserUseCase.execute();

      AppLogger.logStep(3, 4, '중복 요청 방지 검증');
      // 다른 요청이 이미 시작됐다면 무시
      if (state.activeRequestId != currentRequestId) {
        AppLogger.warning(
          '다른 프로필 로드 요청이 진행 중이므로 현재 요청 무시',
          error:
              'RequestID: $currentRequestId vs Current: ${state.activeRequestId}',
        );
        return;
      }

      AppLogger.logStep(4, 4, '프로필 데이터 처리 및 상태 업데이트');
      switch (userProfileResult) {
        case AsyncData(:final value):
          AppLogger.ui('프로필 데이터 로드 성공');
          AppLogger.logState('로드된 사용자 정보', {
            'user_id': PrivacyMaskUtil.maskUserId(value.uid),
            'nickname': PrivacyMaskUtil.maskNickname(value.nickname),
            'streak_days': value.streakDays,
            'has_focus_stats': value.focusStats != null,
          });

          // Member에 이미 포함된 focusStats 활용
          final focusStats = value.focusStats ?? _getDefaultStats();
          AppLogger.logState('프로필 통계 정보', {
            'total_minutes': focusStats.totalMinutes,
            'weekly_minutes_count': focusStats.weeklyMinutes.length,
            'is_default_stats': value.focusStats == null,
          });

          // ✅ 데이터가 0이어도 정상적으로 AsyncData로 설정
          if (state.activeRequestId == currentRequestId) {
            state = state.copyWith(
              userProfile: userProfileResult,
              focusStats: AsyncData(focusStats), // 항상 AsyncData로 설정
              activeRequestId: null,
            );

            final duration = DateTime.now().difference(startTime);
            AppLogger.logPerformance('프로필 데이터 로드', duration);
            AppLogger.logBox(
              '프로필 로드 완료',
              '사용자: ${PrivacyMaskUtil.maskNickname(value.nickname)}\n'
                  '집중시간: ${focusStats.totalMinutes}분\n'
                  '소요시간: ${duration.inMilliseconds}ms',
            );
          } else {
            AppLogger.warning(
              '프로필 로드 완료 시점에 다른 요청이 진행 중이므로 상태 업데이트 무시',
            );
          }

        case AsyncError(:final error, :final stackTrace):
          AppLogger.error(
            '프로필 데이터 로드 실패',
            error: error,
            stackTrace: stackTrace,
          );
          AppLogger.logState('프로필 로드 실패 상세', {
            'request_id': currentRequestId,
            'error_type': error.runtimeType.toString(),
          });

          // 요청 ID가 여전히 유효한지 확인 후 에러 상태 설정
          if (state.activeRequestId == currentRequestId) {
            state = state.copyWith(
              userProfile: userProfileResult,
              focusStats: AsyncError(error, stackTrace),
              activeRequestId: null, // 에러 발생 후 ID 초기화
            );
          }

        case AsyncLoading():
          AppLogger.debug('프로필 데이터 로딩 중 - 이미 로딩 상태로 설정됨');
          // 이미 로딩 상태로 설정했으므로 별도 처리 불필요
          break;
      }
    } catch (e, st) {
      AppLogger.error('프로필 데이터 로드 중 예외 발생', error: e, stackTrace: st);
      AppLogger.logState('프로필 로드 예외 상세', {
        'error_type': e.runtimeType.toString(),
        'has_active_request': state.activeRequestId != null,
      });

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
    AppLogger.debug('기본(빈) 통계 생성');
    return const FocusTimeStats(
      totalMinutes: 0,
      weeklyMinutes: {'월': 0, '화': 0, '수': 0, '목': 0, '금': 0, '토': 0, '일': 0},
    );
  }

  /// 화면 액션 처리
  Future<void> onAction(ProfileAction action) async {
    AppLogger.debug('프로필 액션 처리: ${action.runtimeType}');

    switch (action) {
      case OpenSettings():
        AppLogger.ui('설정 화면 열기 요청 (네비게이션은 UI에서 처리)');
        // 네비게이션은 UI 쪽에서 처리
        break;
      case RefreshProfile():
        AppLogger.ui('수동 프로필 새로고침 요청');
        // 수동 새로고침도 갱신 상태를 통해 처리
        ref.read(profileRefreshStateProvider.notifier).markForRefresh();
        AppLogger.debug('프로필 갱신 상태 마크 완료');
        break;
    }
  }

  /// 명시적 새로고침 메서드 (외부에서 직접 호출 가능)
  Future<void> refresh() async {
    AppLogger.ui('명시적 프로필 새로고침 호출');
    await loadData();
  }
}
