// lib/group/domain/usecase/get_group_locations_use_case.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/map/domain/model/group_member_location.dart';
import 'package:devlink_mobile_app/map/domain/repository/group_location_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetGroupLocationsUseCase {
  final GroupLocationRepository _repository;

  GetGroupLocationsUseCase({required GroupLocationRepository repository})
    : _repository = repository;

  Future<AsyncValue<List<GroupMemberLocation>>> execute(String groupId) async {
    final result = await _repository.getGroupMemberLocations(groupId);

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
