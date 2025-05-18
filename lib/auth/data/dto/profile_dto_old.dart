import 'package:json_annotation/json_annotation.dart';

part 'profile_dto_old.g.dart';

@JsonSerializable()
class ProfileDto {
  const ProfileDto({
    this.userId,
    this.image,
    this.onAir,
    this.description,
    this.position,
    this.skills,
  });

  @JsonKey(name: 'id')
  final String? userId;
  final String? image;
  final bool? onAir;
  final String? description;
  final String? position;
  final String? skills;

  factory ProfileDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileDtoToJson(this);
}
