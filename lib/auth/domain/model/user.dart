import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

@freezed
class User with _$User {
  const User({required this.id, required this.email, required this.nickname});

  final String id;
  final String email;
  final String nickname;
}
