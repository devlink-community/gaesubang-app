// lib/community/data/dto/member_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'member_dto.freezed.dart';
part 'member_dto.g.dart';

/// 실제 Member 모델은 auth 모듈에서 교체 예정!
@freezed
abstract class MemberDto with _$MemberDto {
  const factory MemberDto({
    String? id,
    String? email,
    String? nickname,
    String? uid,
    bool?   onAir,
    String? image,
  }) = _MemberDto;

  factory MemberDto.fromJson(Map<String, dynamic> json) =>
      _$MemberDtoFromJson(json);
}
