import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/map/domain/model/location.dart';
import 'package:devlink_mobile_app/map/domain/model/near_by_items.dart';
import 'package:devlink_mobile_app/map/domain/repository/map_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetNearByItemsUseCase {
  final MapRepository _repository;

  GetNearByItemsUseCase({required MapRepository repository})
    : _repository = repository;

  Future<AsyncValue<NearByItems>> execute(
    Location location,
    double radius,
  ) async {
    final result = await _repository.getNearByItems(location, radius);

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
