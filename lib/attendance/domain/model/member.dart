import 'package:freezed_annotation/freezed_annotation.dart';

part 'member.freezed.dart';

@freezed
class Member with _$Member {
  const Member({
    required this.id,
    required this.email,
    required this.nickname,
    required this.uid,
    this.onAir = false,
    this.image,
  });

  final String id;
  final String email;
  final String nickname;
  final String uid;
  final bool onAir;
  final String? image;
}
