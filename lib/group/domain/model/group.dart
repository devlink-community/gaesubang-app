import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/community/domain/model/hash_tag.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group.freezed.dart';

@freezed
class Group with _$Group {
  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.hashTags,
    required this.limitMemberCount,
    required this.owner,
    this.imageUrl,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final List<Member> members;
  @override
  final List<HashTag> hashTags;
  @override
  final int limitMemberCount;
  @override
  final Member owner;
  @override
  final String? imageUrl;

  // 멤버 수 계산
  int get memberCount => members.length;
}
