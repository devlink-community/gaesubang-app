import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/map/domain/model/location.dart';
import 'package:devlink_mobile_app/map/domain/repository/map_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetCurrentLocationUseCase {
  final MapRepository _repository;

  GetCurrentLocationUseCase({required MapRepository repository})
    : _repository = repository;

  Future<AsyncValue<Location>> execute() async {
    final result = await _repository.getCurrentLocation();

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
