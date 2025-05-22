import 'package:json_annotation/json_annotation.dart';

import '../../../core/utils/firebase_timestamp_converter.dart';

part 'banner_dto.g.dart';

@JsonSerializable()
class BannerDto {
  const BannerDto({
    this.id,
    this.title,
    this.imageUrl,
    this.linkUrl,
    this.isActive,
    this.displayOrder,
    this.startDate,
    this.endDate,
    this.targetAudience,
    this.createdAt,
  });

  final String? id;
  final String? title;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  @JsonKey(name: 'link_url')
  final String? linkUrl;

  @JsonKey(name: 'is_active')
  final bool? isActive;

  @JsonKey(name: 'display_order')
  final num? displayOrder;

  @JsonKey(
    name: 'start_date',
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? startDate;

  @JsonKey(
    name: 'end_date',
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? endDate;

  @JsonKey(name: 'target_audience')
  final String? targetAudience;

  @JsonKey(
    name: 'created_at',
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? createdAt;

  factory BannerDto.fromJson(Map<String, dynamic> json) =>
      _$BannerDtoFromJson(json);

  Map<String, dynamic> toJson() => _$BannerDtoToJson(this);
}