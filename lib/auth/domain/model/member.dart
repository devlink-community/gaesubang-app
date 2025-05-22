// lib/auth/domain/model/member.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../profile/domain/model/focus_time_stats.dart';
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
    this.joinedGroups = const <JoinedGroupDto>[], // 가입한 그룹 목록
    this.focusStats,
    // 새로 추가된 통계 필드들
    this.totalFocusMinutes = 0, // 총 집중시간 (분)
    this.weeklyFocusMinutes = 0, // 이번 주 집중시간 (분)
    this.lastStatsUpdated, // 마지막 통계 업데이트 시간
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
  final FocusTimeStats? focusStats;

  // 새로 추가된 통계 필드들
  final int totalFocusMinutes; // 총 집중시간 (분)
  final int weeklyFocusMinutes; // 이번 주 집중시간 (분)
  final DateTime? lastStatsUpdated; // 마지막 통계 업데이트 시간
}
