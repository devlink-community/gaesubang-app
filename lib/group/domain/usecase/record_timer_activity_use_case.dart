// lib/group/domain/usecase/record_timer_activity_use_case.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/timer_activity_type.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 타이머 활동 기록을 위한 통합 UseCase
/// start, pause, end 모든 타입의 타이머 활동을 처리
class RecordTimerActivityUseCase {
  final GroupRepository _repository;

  RecordTimerActivityUseCase({required GroupRepository repository})
    : _repository = repository;

  /// 현재 시간으로 타이머 활동 기록
  Future<AsyncValue<void>> execute({
    required String groupId,
    required TimerActivityType activityType,
  }) async {
    final result = await _repository.recordTimerActivityWithTimestamp(
      groupId,
      activityType,
      DateTime.now(), // 현재 시간 사용
    );

    return switch (result) {
      Success() => const AsyncData(null),
      Error(failure: final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
  }

  /// 특정 시간으로 타이머 활동 기록
  Future<AsyncValue<void>> executeWithTimestamp({
    required String groupId,
    required TimerActivityType activityType,
    required DateTime timestamp,
  }) async {
    final result = await _repository.recordTimerActivityWithTimestamp(
      groupId,
      activityType,
      timestamp,
    );

    return switch (result) {
      Success() => const AsyncData(null),
      Error(failure: final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
  }

  /// 타이머 시작
  Future<AsyncValue<void>> start(String groupId) async {
    return execute(groupId: groupId, activityType: TimerActivityType.start);
  }

  /// 타이머 일시정지
  Future<AsyncValue<void>> pause(String groupId) async {
    return execute(groupId: groupId, activityType: TimerActivityType.pause);
  }

  /// 타이머 재개
  Future<AsyncValue<void>> resume(String groupId) async {
    return execute(groupId: groupId, activityType: TimerActivityType.resume);
  }

  /// 타이머 종료
  Future<AsyncValue<void>> stop(String groupId) async {
    return execute(groupId: groupId, activityType: TimerActivityType.end);
  }

  /// 특정 시간으로 타이머 시작
  Future<AsyncValue<void>> startWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return executeWithTimestamp(
      groupId: groupId,
      activityType: TimerActivityType.start,
      timestamp: timestamp,
    );
  }

  /// 특정 시간으로 타이머 일시정지
  Future<AsyncValue<void>> pauseWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return executeWithTimestamp(
      groupId: groupId,
      activityType: TimerActivityType.pause,
      timestamp: timestamp,
    );
  }

  /// 특정 시간으로 타이머 재개
  Future<AsyncValue<void>> resumeWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return executeWithTimestamp(
      groupId: groupId,
      activityType: TimerActivityType.resume,
      timestamp: timestamp,
    );
  }

  /// 특정 시간으로 타이머 종료
  Future<AsyncValue<void>> stopWithTimestamp(
    String groupId,
    DateTime timestamp,
  ) async {
    return executeWithTimestamp(
      groupId: groupId,
      activityType: TimerActivityType.end,
      timestamp: timestamp,
    );
  }
}
