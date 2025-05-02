import 'package:freezed_annotation/freezed_annotation.dart';

import 'member.dart';

part 'group.freezed.dart';

@freezed
class Group with _$Group {
  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.hashTag,
    required this.limitMemberCount,
    required this.owner,
  });

  final String id;
  final String name;
  final String description;
  final List<Member> members;
  final String hashTag;
  final int limitMemberCount;
  final String owner;
}
