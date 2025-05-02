// lib/community/domain/model/member.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'member.freezed.dart';

@freezed
abstract class Member with _$Member {
  const factory Member({
    required String id,
    required String email,
    required String nickname,
    required String uid,
    required bool   onAir,
    required String image,
  }) = _Member;
}