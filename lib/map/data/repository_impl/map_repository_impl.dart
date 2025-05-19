import 'dart:async';

import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/map/data/data_source/map_data_source.dart';
import 'package:devlink_mobile_app/map/data/mapper/location_mapper.dart';
import 'package:devlink_mobile_app/map/data/mapper/near_by_items_mapper.dart';
import 'package:devlink_mobile_app/map/domain/model/location.dart';
import 'package:devlink_mobile_app/map/domain/model/near_by_items.dart';
import 'package:devlink_mobile_app/map/domain/repository/map_repository.dart';

class MapRepositoryImpl implements MapRepository {
  final MapDataSource _dataSource;

  MapRepositoryImpl({required MapDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Result<Location>> getCurrentLocation() async {
    try {
      final locationDto = await _dataSource.fetchCurrentLocation();
      return Result.success(locationDto.toModel());
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Future<Result<NearByItems>> getNearByItems(
    Location location,
    double radius,
  ) async {
    try {
      final locationDto = location.toDto();
      final nearByItemsDto = await _dataSource.fetchNearByItems(
        locationDto,
        radius,
      );
      return Result.success(nearByItemsDto.toModel());
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Future<Result<void>> saveLocationData(
    Location location,
    String userId,
  ) async {
    try {
      await _dataSource.saveLocationData(location.toDto(), userId);
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Future<Result<bool>> checkLocationPermission() async {
    try {
      final hasPermission = await _dataSource.checkLocationPermission();
      return Result.success(hasPermission);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Future<Result<bool>> isLocationServiceEnabled() async {
    try {
      final isEnabled = await _dataSource.isLocationServiceEnabled();
      return Result.success(isEnabled);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }
}
