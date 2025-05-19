// lib/auth/domain/usecase/get_focus_stats_use_case.dart
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/focus_stats_calculator.dart';
import 'package:devlink_mobile_app/profile/domain/model/focus_time_stats.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetFocusStatsUseCase {
  final AuthRepository _repository;

  GetFocusStatsUseCase({required AuthRepository repository})
    : _repository = repository;

  Future<AsyncValue<FocusTimeStats>> execute(String userId) async {
    final result = await _repository.getTimerActivities(userId);

    switch (result) {
      case Success(:final data):
        // 타이머 활동 로그를 기반으로 집중 통계 계산
        final focusStats = FocusStatsCalculator.calculateFromActivities(data);
        return AsyncData(focusStats);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
