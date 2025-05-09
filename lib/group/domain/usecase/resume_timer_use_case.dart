import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/timer_session.dart';
import 'package:devlink_mobile_app/group/domain/repository/timer_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ResumeTimerUseCase {
  final TimerRepository _repository;

  ResumeTimerUseCase({required TimerRepository repository})
    : _repository = repository;

  Future<AsyncValue<TimerSession?>> execute(String userId) async {
    // 유저의 진행 중인 타이머 세션이 있는지 확인
    final result = await _repository.getActiveTimerSession(userId);

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
