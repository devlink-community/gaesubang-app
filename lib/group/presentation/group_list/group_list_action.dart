import 'package:freezed_annotation/freezed_annotation.dart';

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
}
