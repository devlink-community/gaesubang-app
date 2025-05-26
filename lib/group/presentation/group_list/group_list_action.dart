import 'package:freezed_annotation/freezed_annotation.dart';

import 'group_sort_type.dart';

part 'group_list_action.freezed.dart';

@freezed
sealed class GroupListAction with _$GroupListAction {
  const factory GroupListAction.onLoadGroupList() = OnLoadGroupList;
  const factory GroupListAction.onTapGroup(String groupId) = OnTapGroup;
  const factory GroupListAction.onJoinGroup(String groupId) = OnJoinGroup;
  const factory GroupListAction.resetSelectedGroup() = ResetSelectedGroup;
  const factory GroupListAction.onTapSearch() = OnTapSearch;
  const factory GroupListAction.onCloseDialog() = OnCloseDialog;
  const factory GroupListAction.onTapCreateGroup() = OnTapCreateGroup;
  const factory GroupListAction.onShowFullGroupDialog() = OnShowFullGroupDialog;

  const factory GroupListAction.onChangeSortType(GroupSortType sortType) =
      OnChangeSortType;

  const factory GroupListAction.onTapSort() = OnTapSort;

  // 🔥 추가: 리프레시 액션
  const factory GroupListAction.onRefreshGroupList() = OnRefreshGroupList;
}
