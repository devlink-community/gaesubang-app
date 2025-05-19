import 'package:freezed_annotation/freezed_annotation.dart';

import 'map_marker.dart';

part 'near_by_items.freezed.dart';

@freezed
class NearByItems with _$NearByItems {
  const NearByItems({required this.groups, required this.users});

  final List<MapMarker> groups;
  final List<MapMarker> users;
}
