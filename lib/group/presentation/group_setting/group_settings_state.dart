// ignore_for_file: annotate_overrides
import 'package:devlink_mobile_app/community/domain/model/hash_tag.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'group_settings_state.freezed.dart';

@freezed
class GroupSettingsState with _$GroupSettingsState {
  const GroupSettingsState({
    this.group = const AsyncValue.loading(),
    this.name = '',
    this.description = '',
    this.imageUrl,
    this.hashTags = const [],
    this.limitMemberCount = 10,
    this.isEditing = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.isOwner = false,
  });

  final AsyncValue<Group> group;
  final String name;
  final String description;
  final String? imageUrl;
  final List<HashTag> hashTags;
  final int limitMemberCount;
  final bool isEditing;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;
  final bool isOwner;
}
