// ignore_for_file: annotate_overrides

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/model/group.dart';
import 'group_sort_type.dart';

part 'group_list_state.freezed.dart';

@freezed
class GroupListState with _$GroupListState {
  const GroupListState({
    this.groupList = const AsyncValue.loading(),
    this.selectedGroup = const AsyncValue.data(null),
    this.joinGroupResult = const AsyncValue.data(null),
    this.sortType = GroupSortType.latest, // 🔧 새로 추가: 기본값은 최신순
  });

  final AsyncValue<List<Group>> groupList;
  final AsyncValue<Group?> selectedGroup;
  final AsyncValue<void> joinGroupResult;
  final GroupSortType sortType; // 🔧 새로 추가: 현재 정렬 타입
}
