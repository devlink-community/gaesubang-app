import 'package:devlink_mobile_app/map/domain/model/location.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'map_marker.freezed.dart';

/// 마커의 타입을 나타내는 열거형
enum MarkerType { group, user }

@freezed
class MapMarker with _$MapMarker {
  const MapMarker({
    required this.id,
    required this.title,
    required this.location,
    required this.type,
    this.description = '',
    this.imageUrl = '',
    this.memberCount = 0,
    this.limitMemberCount = 0,
  });

  final String id;
  final String title;
  final String description;
  final Location location;
  final MarkerType type;
  final String imageUrl;

  // 그룹일 경우에 사용되는 필드
  final int memberCount;
  final int limitMemberCount;
}
