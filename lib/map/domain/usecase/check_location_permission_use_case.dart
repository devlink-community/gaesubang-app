import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/map/domain/repository/map_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CheckLocationPermissionUseCase {
  final MapRepository _repository;

  CheckLocationPermissionUseCase({required MapRepository repository})
    : _repository = repository;

  Future<AsyncValue<bool>> execute() async {
    final result = await _repository.checkLocationPermission();

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
