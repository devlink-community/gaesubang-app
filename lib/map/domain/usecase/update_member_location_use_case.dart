import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/map/domain/repository/group_location_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UpdateMemberLocationUseCase {
  final GroupLocationRepository _repository;

  UpdateMemberLocationUseCase({required GroupLocationRepository repository})
    : _repository = repository;

  Future<AsyncValue<void>> execute(
    String groupId,
    String memberUserId,
    double latitude,
    double longitude,
  ) async {
    final result = await _repository.updateMemberLocation(
      groupId,
      memberUserId,
      latitude,
      longitude,
    );

    switch (result) {
      case Success():
        return const AsyncData(null);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
