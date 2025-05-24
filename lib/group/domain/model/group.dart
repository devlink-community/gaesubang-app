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
    required this.isJoinedByCurrentUser,
    required this.pauseTimeLimit, // 추가: 일시정지 제한시간 (분 단위)
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final String? imageUrl;
  @override
  final DateTime createdAt;
  @override
  final String ownerId;
  @override
  final String? ownerNickname;
  @override
  final String? ownerProfileImage;
  @override
  final int maxMemberCount;
  @override
  final List<String> hashTags;
  @override
  final int memberCount;
  @override
  final bool isJoinedByCurrentUser;
  @override
  final int pauseTimeLimit; // 새 필드
}
