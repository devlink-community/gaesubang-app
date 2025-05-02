import 'package:freezed_annotation/freezed_annotation.dart';

part 'member.freezed.dart';

@freezed
class Member with _$Member {
  const Member({
    required this.id,
    required this.email,
    required this.nickname,
    this.imagePath = "",
    this.onAir = false,
  });

  final String id;
  final String email;
  final String nickname;
  final String imagePath;
  final bool onAir;
}
