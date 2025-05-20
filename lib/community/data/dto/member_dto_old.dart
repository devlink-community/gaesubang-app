// lib/community/data/dto/member_dto_old.dart
import 'package:json_annotation/json_annotation.dart';

part 'member_dto_old.g.dart';

@JsonSerializable()
class MemberDto {
  const MemberDto({
    this.id,
    this.email,
    this.nickname,
    this.uid,
    this.description,
    this.onAir,
    this.image,
  });

  final String? id;
  final String? email;
  final String? nickname;
  final String? uid;
  final String? description;
  final bool? onAir;
  final String? image;

  factory MemberDto.fromJson(Map<String, dynamic> json) =>
      _$MemberDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MemberDtoToJson(this);
}
