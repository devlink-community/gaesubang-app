import 'package:json_annotation/json_annotation.dart';

part 'profile_dto.g.dart';

@JsonSerializable()
class ProfileDto {
  const ProfileDto({this.userId, this.image, this.onAir});

  @JsonKey(name: 'id')
  final String? userId;
  final String? image;
  final bool? onAir;

  factory ProfileDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileDtoToJson(this);
}
