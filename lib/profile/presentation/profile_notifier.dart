import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/model/member.dart';
import '../../auth/domain/usecase/get_current_user_use_case.dart';
import '../../auth/module/auth_di.dart';
import '../domain/model/focus_time_stats.dart';
import 'profile_action.dart';
import 'profile_state.dart';

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<ProfileState>>(
      (ref) => ProfileNotifier(
        getCurrentUserUseCase: ref.watch(getCurrentUserUseCaseProvider),
      ),
    );

/// ProfileNotifier - auth 모듈의 UseCase를 사용하도록 변경
class ProfileNotifier extends StateNotifier<AsyncValue<ProfileState>> {
  final GetCurrentUserUseCase getCurrentUserUseCase;

  ProfileNotifier({required this.getCurrentUserUseCase})
    : super(const AsyncValue.loading()) {
    // 초기화 직후 데이터 로드 시작
    _loadData();
  }

  // 데이터 로드 메서드
  Future<void> _loadData() async {
    try {
      // 로딩 상태로 변경
      state = const AsyncValue.loading();

      // 프로필 로드 (auth 모듈 사용)
      late AsyncValue<Member> userProfileResult;
      try {
        userProfileResult = await getCurrentUserUseCase.execute();
      } catch (e, st) {
        userProfileResult = AsyncValue.error(e, st);
      }

      // 통계 로드 (임시로 Mock 데이터 생성)
      late AsyncValue<FocusTimeStats> focusStatsResult;
      try {
        // TODO: 나중에 auth 모듈에 통계 관련 UseCase 추가 시 변경
        final mockStats = FocusTimeStats(
          totalMinutes: 1234,
          weeklyMinutes: {
            '월': 120,
            '화': 150,
            '수': 90,
            '목': 200,
            '금': 180,
            '토': 300,
            '일': 194,
          },
        );
        focusStatsResult = AsyncValue.data(mockStats);
      } catch (e, st) {
        focusStatsResult = AsyncValue.error(e, st);
      }

      // 최종 상태 생성
      final newState = ProfileState(
        userProfile: userProfileResult,
        focusStats: focusStatsResult,
      );

      // 상태 업데이트
      state = AsyncValue.data(newState);
    } catch (e, st) {
      debugPrint('데이터 로드 중 오류 발생: $e');
      // 오류 발생 시 에러 상태로 변경
      state = AsyncValue.error(e, st);
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
