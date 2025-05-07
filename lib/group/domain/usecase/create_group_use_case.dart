import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CreateGroupUseCase {
  final GroupRepository _repository;

  CreateGroupUseCase({required GroupRepository repository})
    : _repository = repository;

  Future<AsyncValue<Group>> execute(Group group) async {
    final result = await _repository.createGroup(group);

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, StackTrace.current);
    }
  }
}
