import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UpdateGroupUseCase {
  final GroupRepository _repository;

  UpdateGroupUseCase({required GroupRepository repository})
    : _repository = repository;

  Future<AsyncValue<void>> execute(Group group) async {
    final result = await _repository.updateGroup(group);

    switch (result) {
      case Success():
        return const AsyncData(null);
      case Error(failure: final failure):
        return AsyncError(failure, StackTrace.current);
    }
  }
}
