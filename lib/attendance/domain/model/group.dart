import 'package:freezed_annotation/freezed_annotation.dart';

part 'group.freezed.dart';

@freezed
class Group with _$Group {
  final String id;
  final String name;
  final String description;
  final List<Member> members;
  final List<String> hashTags;
  final int limitMemberCount;
  final Member owner;

  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.hashTags,
    required this.limitMemberCount,
    required this.owner,
  });
}
