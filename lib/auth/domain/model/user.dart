// lib/auth/domain/model/user.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/dto/joined_group_dto.dart';
import 'summary.dart';

part 'user.freezed.dart';

@freezed
class User with _$User {
  const User({
    required this.id,
    required this.email,
    required this.nickname,
    required this.uid,
    this.image = "",
    this.onAir = false,
    this.description = "",
    this.position = "",
    this.skills = "",
    this.joinedGroups = const <JoinedGroupDto>[],
    this.summary, // 새로운 요약 정보
  });

  final String id;
  final String email;
  final String nickname;
  final String uid;
  final String image;
  final bool onAir;
  final String description;
  final String? position;
  final String? skills;
  final List<JoinedGroupDto> joinedGroups;
  final Summary? summary; // 새로운 통합 요약 정보
}
