// ignore_for_file: annotate_overrides
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/community/domain/model/hash_tag.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_create_state.freezed.dart';

@freezed
class GroupCreateState with _$GroupCreateState {
  final String name;
  final String description;
  final int limitMemberCount;
  final String? imageUrl;
  final List<HashTag> hashTags;
  final List<Member> invitedMembers;
  final bool isSubmitting;
  final String? errorMessage;
  final String? createdGroupId;

  const GroupCreateState({
    this.name = '',
    this.description = '',
    this.limitMemberCount = 10,
    this.imageUrl,
    this.hashTags = const [],
    this.invitedMembers = const [],
    this.isSubmitting = false,
    this.errorMessage,
    this.createdGroupId,
  });
}
