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
  });

  final String id;
  final String userId;
  final String userName;
  final String? profileUrl;
  final String role; // "owner", "member"
  final DateTime joinedAt;

  // 관리자 여부 확인 헬퍼 메서드
  bool get isOwner => role == "owner";
}
