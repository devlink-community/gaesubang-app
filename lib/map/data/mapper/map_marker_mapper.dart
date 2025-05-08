import 'package:devlink_mobile_app/map/data/dto/map_marker_dto.dart';
import 'package:devlink_mobile_app/map/data/mapper/location_mapper.dart';
import 'package:devlink_mobile_app/map/domain/model/location.dart';
import 'package:devlink_mobile_app/map/domain/model/map_marker.dart';

extension MapMarkerDtoMapper on MapMarkerDto {
  MapMarker toModel() {
    return MapMarker(
      id: id ?? '',
      title: title ?? '',
      description: description ?? '',
      location:
          location?.toModel() ?? const Location(latitude: 0, longitude: 0),
      type: type?.toLowerCase() == 'user' ? MarkerType.user : MarkerType.group,
      imageUrl: imageUrl ?? '',
      memberCount: memberCount ?? 0,
      limitMemberCount: limitMemberCount ?? 0,
    );
  }
}

extension MapMarkerModelMapper on MapMarker {
  MapMarkerDto toDto() {
    return MapMarkerDto(
      id: id,
      title: title,
      description: description,
      location: location.toDto(),
      type: type == MarkerType.user ? 'user' : 'group',
      imageUrl: imageUrl,
      memberCount: memberCount,
      limitMemberCount: limitMemberCount,
    );
  }
}

extension MapMarkerDtoListMapper on List<MapMarkerDto>? {
  List<MapMarker> toModelList() => this?.map((e) => e.toModel()).toList() ?? [];
}
