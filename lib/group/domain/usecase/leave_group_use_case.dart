import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LeaveGroupUseCase {
  final GroupRepository _repository;

  LeaveGroupUseCase({required GroupRepository repository})
    : _repository = repository;

  Future<AsyncValue<void>> execute(String groupId) async {
    final result = await _repository.leaveGroup(groupId);

    switch (result) {
      case Success():
        return const AsyncData(null);
      case Error(failure: final failure):
        return AsyncError(failure, StackTrace.current);
    }
  }
}
