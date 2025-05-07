import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/timer_session.dart';
import 'package:devlink_mobile_app/group/domain/repository/timer_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class StopTimerUseCase {
  final TimerRepository _repository;

  StopTimerUseCase({required TimerRepository repository})
    : _repository = repository;

  Future<AsyncValue<TimerSession>> execute({
    required String sessionId,
    required int duration,
  }) async {
    final result = await _repository.stopTimer(
      sessionId: sessionId,
      duration: duration,
    );

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
