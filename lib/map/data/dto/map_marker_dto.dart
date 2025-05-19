import 'package:json_annotation/json_annotation.dart';

import 'location_dto.dart';

part 'map_marker_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class MapMarkerDto {
  const MapMarkerDto({
    this.id,
    this.title,
    this.description,
    this.location,
    this.type,
    this.imageUrl,
    this.memberCount,
    this.limitMemberCount,
  });

  final String? id;
  final String? title;
  final String? description;
  final LocationDto? location;

  // 마커 타입 (group 또는 user)
  final String? type;

  // 아이콘 또는 프로필 이미지 URL
  final String? imageUrl;

  // 그룹일 경우 멤버 수
  final int? memberCount;

  // 그룹일 경우 제한 멤버 수
  final int? limitMemberCount;

  factory MapMarkerDto.fromJson(Map<String, dynamic> json) =>
      _$MapMarkerDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MapMarkerDtoToJson(this);
}
