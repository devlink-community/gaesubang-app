import 'package:devlink_mobile_app/map/data/dto/location_dto.dart';
import 'package:devlink_mobile_app/map/domain/model/location.dart';

extension LocationDtoMapper on LocationDto {
  Location toModel() {
    return Location(
      latitude: latitude?.toDouble() ?? 0.0,
      longitude: longitude?.toDouble() ?? 0.0,
      address: address ?? '',
      timestamp: timestamp,
    );
  }
}

extension LocationModelMapper on Location {
  LocationDto toDto() {
    return LocationDto(
      latitude: latitude,
      longitude: longitude,
      address: address,
      timestamp: timestamp,
    );
  }
}

extension LocationDtoListMapper on List<LocationDto>? {
  List<Location> toModelList() => this?.map((e) => e.toModel()).toList() ?? [];
}
