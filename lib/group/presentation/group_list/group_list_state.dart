import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../domain/model/group.dart';

part 'group_list_state.freezed.dart';

@freezed
class GroupListState with _$GroupListState {
  final AsyncValue<List<Group>> groupList;
  final AsyncValue<Group?> selectedGroup;
  final AsyncValue<void> joinGroupResult;

  const GroupListState({
    this.groupList = const AsyncValue.loading(),
    this.selectedGroup = const AsyncValue.data(null),
    this.joinGroupResult = const AsyncValue.data(null),
  });
}
