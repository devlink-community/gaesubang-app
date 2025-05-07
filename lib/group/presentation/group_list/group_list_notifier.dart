import 'package:devlink_mobile_app/group/module/group_di.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/usecase/get_group_list_use_case.dart';
import '../../domain/usecase/get_group_detail_use_case.dart';
import '../../domain/usecase/join_group_use_case.dart';

part 'group_list_notifier.g.dart';

@riverpod
class GroupListNotifier extends _$GroupListNotifier {
  late final GetGroupListUseCase _getGroupListUseCase;
  late final GetGroupDetailUseCase _getGroupDetailUseCase;
  late final JoinGroupUseCase _joinGroupUseCase;

  @override
  GroupListState build() {
    _getGroupListUseCase = ref.watch(getGroupListUseCaseProvider);
    _getGroupDetailUseCase = ref.watch(getGroupDetailUseCaseProvider);
    _joinGroupUseCase = ref.watch(joinGroupUseCaseProvider);

    _loadGroupList();

    return const GroupListState();
  }

  Future<void> _loadGroupList() async {
    final asyncResult = await _getGroupListUseCase.execute();
    state = state.copyWith(groupList: asyncResult);
  }

  Future<void> _getGroupDetail(String groupId) async {
    state = state.copyWith(selectedGroup: const AsyncLoading());
    final asyncResult = await _getGroupDetailUseCase.execute(groupId);
    state = state.copyWith(selectedGroup: asyncResult);
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
        await _getGroupDetail(groupId);
      case OnJoinGroup(:final groupId):
        await _joinGroup(groupId);
      case OnTapSearch():
        // 검색 화면은 Root에서 처리
        break;
      case OnCloseDialog():
        // 다이얼로그 닫기는 Root에서 처리
        break;
      case OnTapCreateGroup():
        // 그룹 생성 화면은 Root에서 처리
        break;
    }
  }
}
