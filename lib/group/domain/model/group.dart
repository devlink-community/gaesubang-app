// lib/group/domain/model/group.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group.freezed.dart';

@freezed
class Group with _$Group {
  const Group({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.createdAt,
    required this.ownerId,
    this.ownerNickname,
    this.ownerProfileImage,
    required this.maxMemberCount,
    required this.hashTags,
    required this.memberCount,
    this.isJoinedByCurrentUser = false,
    this.pauseTimeLimit = 120, // 추가: 기본값 120분 (2시간)
  });

  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final DateTime createdAt;
  final String ownerId;
  final String? ownerNickname;
  final String? ownerProfileImage;
  final int maxMemberCount;
  final List<String> hashTags;
  final int memberCount;
  final bool isJoinedByCurrentUser;
  final int pauseTimeLimit; // 추가: 일시정지 제한시간 (분 단위)

  // 멤버 수 제한 도달 여부 헬퍼 메서드
  bool get isOpen => memberCount < maxMemberCount;

  // 현재 사용자가 방장인지 확인하는 헬퍼 메서드
  bool isOwner(String userId) => ownerId == userId;
}
