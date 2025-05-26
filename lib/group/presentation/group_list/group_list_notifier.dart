import 'package:devlink_mobile_app/core/firebase/firebase_providers.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/module/group_di.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_state.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_sort_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/usecase/get_group_list_use_case.dart';
import '../../domain/usecase/management/join_group_use_case.dart';

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

    // 로드된 그룹 목록을 현재 정렬 타입에 따라 정렬
    _sortGroupList();
  }

  // 🔥 추가: 외부에서 호출 가능한 refresh 메서드
  Future<void> refresh() async {
    // 로딩 상태로 변경
    state = state.copyWith(groupList: const AsyncValue.loading());

    // 그룹 목록 다시 로드
    await _loadGroupList();
  }

  // 그룹 목록 정렬 메서드 추가
  void _sortGroupList() {
    if (state.groupList is AsyncData) {
      final groups = [...(state.groupList as AsyncData<List<Group>>).value];

      switch (state.sortType) {
        case GroupSortType.latest:
          // 생성일 기준 내림차순 정렬 (최신순)
          groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        case GroupSortType.popular:
          // 멤버 수 기준 내림차순 정렬 (인기순)
          groups.sort((a, b) => b.memberCount.compareTo(a.memberCount));
      }

      state = state.copyWith(groupList: AsyncData(groups));
    }
  }

  // 정렬 타입 변경 메서드 추가
  void _changeSortType(GroupSortType sortType) {
    if (state.sortType != sortType) {
      state = state.copyWith(sortType: sortType);
      _sortGroupList();
    }
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
    // 1. 사용자가 그룹에 이미 가입되어 있는지 확인
    if (group.isJoinedByCurrentUser) {
      return true;
    }

    // 2. 사용자가 그룹의 소유자인지 확인 (소유자는 무조건 가입된 상태)
    final currentUserId = _getCurrentUserId();

    // 소유자인 경우 자동으로 가입된 상태로 간주
    return group.ownerId == currentUserId;
  }

  // 현재 사용자 ID 가져오기 헬퍼 메서드
  String _getCurrentUserId() {
    // Firebase Auth에서 현재 사용자 ID 가져오기
    final auth = ref.read(firebaseAuthProvider);
    return auth.currentUser?.uid ?? '';
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
      case OnRefreshGroupList(): // 🔥 추가: 누락된 액션 처리
        await refresh();
      case OnTapGroup(:final groupId):
        _selectGroup(groupId);
      case OnJoinGroup(:final groupId):
        await _joinGroup(groupId);
      case ResetSelectedGroup():
        // selectedGroup 초기화
        state = state.copyWith(selectedGroup: const AsyncData(null));
      case OnShowFullGroupDialog():
        // 인원 마감 다이얼로그 액션 - Root에서 처리하므로 여기서는 단순 분기만
        break;
      case OnTapSearch():
        break;
      case OnCloseDialog():
        break;
      case OnTapCreateGroup():
        break;
      case OnTapSort():
        // 이 액션은 UI에서만 사용되므로 여기서는 아무 작업도 하지 않음
        break;
      case OnChangeSortType(:final sortType):
        _changeSortType(sortType);
    }
  }
}
