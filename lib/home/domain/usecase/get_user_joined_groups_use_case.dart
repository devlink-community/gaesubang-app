import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetUserJoinedGroupsUseCase {
  final GroupRepository _groupRepository;

  GetUserJoinedGroupsUseCase({required GroupRepository groupRepository})
    : _groupRepository = groupRepository;

  Future<AsyncValue<List<Group>>> execute(String userId) async {
    final result = await _groupRepository.getUserJoinedGroups(userId);

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
