// lib/group/domain/usecase/stop_timer_use_case.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class StopTimerUseCase {
  final GroupRepository _repository;

  StopTimerUseCase({required GroupRepository repository})
    : _repository = repository;

  Future<AsyncValue<void>> execute(String groupId) async {
    final result = await _repository.stopMemberTimer(groupId);

    return switch (result) {
      Success() => const AsyncData(null),
      Error(failure: final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
  }
}
