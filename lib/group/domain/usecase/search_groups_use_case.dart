// lib/group/domain/usecase/search_groups_use_case.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SearchGroupsUseCase {
  final GroupRepository _repository;

  SearchGroupsUseCase({required GroupRepository repository})
    : _repository = repository;

  Future<AsyncValue<List<Group>>> execute(String query) async {
    final result = await _repository.searchGroups(query);

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, StackTrace.current);
    }
  }
}
