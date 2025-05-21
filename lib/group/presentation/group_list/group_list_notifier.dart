import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/module/group_di.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/usecase/get_group_list_use_case.dart';
import '../../domain/usecase/join_group_use_case.dart';

part 'group_list_notifier.g.dart';

@riverpod
class GroupListNotifier extends _$GroupListNotifier {
  late final GetGroupListUseCase _getGroupListUseCase;
  late final JoinGroupUseCase _joinGroupUseCase;

  @override
  GroupListState build() {
    _getGroupListUseCase = ref.watch(getGroupListUseCaseProvider);
    _joinGroupUseCase = ref.watch(joinGroupUseCaseProvider);

    _loadGroupList();

    return const GroupListState();
  }

  Future<void> _loadGroupList() async {
    final asyncResult = await _getGroupListUseCase.execute();
    state = state.copyWith(groupList: asyncResult);
  }

  void _selectGroup(String groupId) {
    if (state.groupList is AsyncData) {
      final groups = (state.groupList as AsyncData<List<Group>>).value;
      final selectedGroup = groups.firstWhere(
        (group) => group.id == groupId,
        orElse: () => throw Exception('그룹을 찾을 수 없습니다'),
      );
      state = state.copyWith(selectedGroup: AsyncData(selectedGroup));
    }
  }

  bool isCurrentMemberInGroup(Group group) {
    // 현재 사용자가 그룹에 속해 있는지 확인하는 로직
    // 필요에 따라 수정해야 함 (예: 사용자 정보는 다른 Provider나 캐시에서 가져와야 할 수 있음)
    return group.isJoinedByCurrentUser;
  }

  Future<void> _joinGroup(String groupId) async {
    state = state.copyWith(joinGroupResult: const AsyncLoading());
    final asyncResult = await _joinGroupUseCase.execute(groupId);
    state = state.copyWith(joinGroupResult: asyncResult);
  }

  Future<void> onAction(GroupListAction action) async {
    switch (action) {
      case OnLoadGroupList():
        await _loadGroupList();
      case OnTapGroup(:final groupId):
        _selectGroup(groupId);
      case OnJoinGroup(:final groupId):
        await _joinGroup(groupId);
      case ResetSelectedGroup():
        // selectedGroup 초기화
        state = state.copyWith(selectedGroup: const AsyncData(null));
      case OnTapSearch():
        break;
      case OnCloseDialog():
        break;
      case OnTapCreateGroup():
        break;
    }
  }
}
