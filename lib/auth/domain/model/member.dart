// lib/auth/domain/model/member.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/dto/joined_group_dto.dart';

part 'member.freezed.dart';

@freezed
class Member with _$Member {
  const Member({
    required this.id,
    required this.email,
    required this.nickname,
    required this.uid,
    this.image = "",
    this.onAir = false,
    this.agreedTermsId,
    this.description = "",
    this.streakDays = 0,
    this.position = "",
    this.skills = "",
    this.joinedGroups = const <JoinedGroupDto>[], // JoinedGroupDto 리스트 추가
  });

  final String id;
  final String email;
  final String nickname;
  final String uid;
  final String image;
  final bool onAir;
  final String? agreedTermsId;
  final String description;
  final int streakDays;
  final String? position;
  final String? skills;
  final List<JoinedGroupDto> joinedGroups; // 가입한 그룹 목록
}
