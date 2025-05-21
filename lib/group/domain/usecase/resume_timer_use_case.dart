// lib/group/domain/usecase/resume_timer_use_case.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ResumeTimerUseCase {
  final GroupRepository _repository;

  ResumeTimerUseCase({required GroupRepository repository})
    : _repository = repository;

  Future<AsyncValue<void>> execute(String groupId) async {
    final result = await _repository.pauseMemberTimer(groupId);

    return switch (result) {
      Success() => const AsyncData(null),
      Error(failure: final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
  }
}
