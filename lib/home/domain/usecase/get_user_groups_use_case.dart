import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/home/domain/repository/home_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetUserGroupsUseCase {
  final HomeRepository _repository;

  GetUserGroupsUseCase({required HomeRepository repository})
    : _repository = repository;

  Future<AsyncValue<List<Group>>> execute() async {
    final result = await _repository.getUserGroups();

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
