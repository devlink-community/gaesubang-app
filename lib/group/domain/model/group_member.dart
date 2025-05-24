// lib/group/domain/model/group_member.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_member.freezed.dart';

@freezed
class GroupMember with _$GroupMember {
  const GroupMember({
    required this.id,
    required this.userId,
    required this.userName,
    this.profileUrl,
    required this.role,
    required this.joinedAt,
    required this.isActive,
    this.timerStartTime,
    required this.elapsedMinutes,
    required this.elapsedSeconds,
  });

  @override
  final String id;
  @override
  final String userId;
  @override
  final String userName;
  @override
  final String? profileUrl;
  @override
  final String role; // "owner", "member"
  @override
  final DateTime joinedAt;
  @override
  final bool isActive; // 타이머 실행 중 여부
  @override
  final DateTime? timerStartTime; // 타이머 시작 시간
  @override
  final int elapsedMinutes; // 경과 시간 (분)
  @override
  final int elapsedSeconds; // 경과 시간 (초)
}
