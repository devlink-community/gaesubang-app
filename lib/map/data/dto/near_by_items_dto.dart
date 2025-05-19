import 'package:json_annotation/json_annotation.dart';

import 'map_marker_dto.dart';

part 'near_by_items_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class NearByItemsDto {
  const NearByItemsDto({this.groups, this.users});

  final List<MapMarkerDto>? groups;
  final List<MapMarkerDto>? users;

  factory NearByItemsDto.fromJson(Map<String, dynamic> json) =>
      _$NearByItemsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$NearByItemsDtoToJson(this);
}
