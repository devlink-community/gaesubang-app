import 'package:json_annotation/json_annotation.dart';

part 'location_dto.g.dart';

@JsonSerializable()
class LocationDto {
  const LocationDto({
    this.latitude,
    this.longitude,
    this.address,
    this.timestamp,
  });

  final num? latitude;
  final num? longitude;
  final String? address;
  final int? timestamp;

  factory LocationDto.fromJson(Map<String, dynamic> json) =>
      _$LocationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LocationDtoToJson(this);
}
