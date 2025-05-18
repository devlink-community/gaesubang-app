// ignore_for_file: annotate_overrides

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../auth/domain/model/member.dart';
import '../../domain/model/group.dart';

part 'group_list_state.freezed.dart';

@freezed
class GroupListState with _$GroupListState {
  final AsyncValue<List<Group>> groupList;
  final AsyncValue<Group?> selectedGroup;
  final AsyncValue<void> joinGroupResult;
  final Member? currentMember;

  const GroupListState({
    this.groupList = const AsyncValue.loading(),
    this.selectedGroup = const AsyncValue.data(null),
    this.joinGroupResult = const AsyncValue.data(null),
    this.currentMember,
  });
}
