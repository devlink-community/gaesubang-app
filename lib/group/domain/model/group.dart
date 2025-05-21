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
    required this.ownerId, // createdBy를 ownerId로 변경
    this.ownerNickname, // 추가: 방장 닉네임
    this.ownerProfileImage, // 추가: 방장 프로필 이미지
    required this.maxMemberCount,
    required this.hashTags,
    required this.memberCount,
    this.isJoinedByCurrentUser = false,
  });

  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final DateTime createdAt;
  final String ownerId; // 필드명 변경
  final String? ownerNickname; // 추가
  final String? ownerProfileImage; // 추가
  final int maxMemberCount;
  final List<String> hashTags;
  final int memberCount;
  final bool isJoinedByCurrentUser;

  // 멤버 수 제한 도달 여부 헬퍼 메서드
  bool get isOpen => memberCount < maxMemberCount;

  // 현재 사용자가 방장인지 확인하는 헬퍼 메서드 추가
  bool isOwner(String userId) => ownerId == userId;
}
