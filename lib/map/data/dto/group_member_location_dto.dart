import 'package:devlink_mobile_app/core/utils/firebase_timestamp_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_member_location_dto.g.dart';

@JsonSerializable()
class GroupMemberLocationDto {
  const GroupMemberLocationDto({
    this.userId,
    this.nickname,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.lastUpdated,
    this.isOnline,
  });

  final String? userId;
  final String? nickname;
  final String? imageUrl;
  final num? latitude;
  final num? longitude;

  @JsonKey(
    fromJson: FirebaseTimestampConverter.timestampFromJson,
    toJson: FirebaseTimestampConverter.timestampToJson,
  )
  final DateTime? lastUpdated;
  final bool? isOnline;

  factory GroupMemberLocationDto.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberLocationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GroupMemberLocationDtoToJson(this);
}
