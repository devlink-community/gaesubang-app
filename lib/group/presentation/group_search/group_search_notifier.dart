// lib/group/presentation/group_search/group_search_notifier.dart
import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/usecase/join_group_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/search_groups_use_case.dart';
import 'package:devlink_mobile_app/group/module/group_di.dart';
import 'package:devlink_mobile_app/group/presentation/group_search/group_search_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_search/group_search_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_search_notifier.g.dart';

@riverpod
class GroupSearchNotifier extends _$GroupSearchNotifier {
  late final SearchGroupsUseCase _searchGroupsUseCase;
  late final JoinGroupUseCase _joinGroupUseCase;

  @override
  GroupSearchState build() {
    _searchGroupsUseCase = ref.watch(searchGroupsUseCaseProvider);
    _joinGroupUseCase = ref.watch(joinGroupUseCaseProvider);

    // 현재 사용자 정보를 auth provider에서 가져옴
    final currentUser = ref.watch(currentUserProvider);

    // 최근 검색어는 로컬 저장소에서 가져올 수 있지만, 여기서는 간단히 하드코딩
    final recentSearches = ['정보처리기사', '개발자', '스터디'];

    return GroupSearchState(
      recentSearches: recentSearches,
      currentMember: currentUser,
    );
  }

  void _selectGroup(String groupId) {
    if (state.searchResults is AsyncData) {
      final groups = (state.searchResults as AsyncData<List<Group>>).value;
      final selectedGroup = groups.firstWhere(
        (group) => group.id == groupId,
        orElse: () => throw Exception('그룹을 찾을 수 없습니다'),
      );
      state = state.copyWith(selectedGroup: AsyncData(selectedGroup));
    }
  }

  bool isCurrentMemberInGroup(Group group) {
    final currentMember = state.currentMember;
    if (currentMember == null) return false;

    // Group 모델에 따라 현재 사용자가 그룹에 속해 있는지 확인하는 로직
    // 1. 사용자가 그룹의 소유자인지 확인
    if (group.ownerId == currentMember.id) return true;

    // 2. 사용자가 참여한 그룹 목록에 해당 그룹이 있는지 확인
    return currentMember.joinedGroups.any(
      (joinedGroup) => joinedGroup.groupName == group.name,
    );
  }

  Future<void> _joinGroup(String groupId) async {
    state = state.copyWith(joinGroupResult: const AsyncLoading());
    final asyncResult = await _joinGroupUseCase.execute(groupId);
    state = state.copyWith(joinGroupResult: asyncResult);
  }

  Future<void> onAction(GroupSearchAction action) async {
    switch (action) {
      case OnSearch(:final query):
        if (query.trim().isEmpty) return;

        // 1. 쿼리 업데이트
        state = state.copyWith(query: query);

        // 2. 로딩 상태로 변경
        state = state.copyWith(searchResults: const AsyncLoading());

        // 3. 검색 수행
        final results = await _searchGroupsUseCase.execute(query);

        // 4. 결과 반영
        state = state.copyWith(searchResults: results);

        // 5. 최근 검색어에 추가 (맨 앞에 추가)
        if (!state.recentSearches.contains(query)) {
          final updatedRecentSearches = [query, ...state.recentSearches];
          // 최대 5개만 유지
          if (updatedRecentSearches.length > 5) {
            updatedRecentSearches.removeLast();
          }
          state = state.copyWith(recentSearches: updatedRecentSearches);
        } else {
          // 이미 있으면 맨 앞으로 이동 (삭제 후 맨 앞에 추가)
          final updatedRecentSearches = [...state.recentSearches];
          updatedRecentSearches.remove(query);
          updatedRecentSearches.insert(0, query);
          state = state.copyWith(recentSearches: updatedRecentSearches);
        }

      case OnClearSearch():
        state = state.copyWith(
          query: '',
          searchResults: const AsyncValue.data([]),
        );

      case OnTapGroup(:final groupId):
        _selectGroup(groupId);
        break;

      case OnGoBack():
        break;
      case OnRemoveRecentSearch(:final query):
        final updatedRecentSearches = [...state.recentSearches]..remove(query);
        state = state.copyWith(recentSearches: updatedRecentSearches);

      case OnClearAllRecentSearches():
        state = state.copyWith(recentSearches: []);

      case OnJoinGroup(:final groupId):
        await _joinGroup(groupId);

      case ResetSelectedGroup():
        // selectedGroup 초기화
        state = state.copyWith(selectedGroup: const AsyncData(null));
      case OnCloseDialog():
        // 다이얼로그 닫을 때 selectedGroup 초기화
        state = state.copyWith(selectedGroup: const AsyncData(null));
        break;
    }
  }
}
