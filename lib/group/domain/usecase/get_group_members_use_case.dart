// lib/group/domain/usecase/get_group_members_use_case.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetGroupMembersUseCase {
  final GroupRepository _repository;

  GetGroupMembersUseCase({required GroupRepository repository})
    : _repository = repository;

  Future<AsyncValue<List<GroupMember>>> execute(String groupId) async {
    final result = await _repository.getGroupMembers(groupId);

    return switch (result) {
      Success(:final data) => AsyncData(data),
      Error(:final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
  }
}
