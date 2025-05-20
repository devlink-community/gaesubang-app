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
    required this.createdBy,
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
  final String createdBy;
  final int maxMemberCount;
  final List<String> hashTags;
  final int memberCount;
  final bool isJoinedByCurrentUser;

  // 멤버 수 제한 도달 여부 헬퍼 메서드
  bool get isOpen => memberCount < maxMemberCount;
}
