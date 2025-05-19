import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/map/domain/model/location.dart';
import 'package:devlink_mobile_app/map/domain/repository/map_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SaveLocationDataUseCase {
  final MapRepository _repository;

  SaveLocationDataUseCase({required MapRepository repository})
    : _repository = repository;

  Future<AsyncValue<void>> execute(Location location, String userId) async {
    final result = await _repository.saveLocationData(location, userId);

    switch (result) {
      case Success():
        return const AsyncData(null);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
