import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/core/service/search_history_service.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/usecase/join_group_use_case.dart';
import 'package:devlink_mobile_app/group/domain/usecase/search_groups_use_case.dart';
import 'package:devlink_mobile_app/group/module/group_di.dart';
import 'package:devlink_mobile_app/group/presentation/group_search/group_search_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_search/group_search_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_search_notifier.g.dart';

@Riverpod(keepAlive: true)
class GroupSearchNotifier extends _$GroupSearchNotifier {
  late final SearchGroupsUseCase _searchGroupsUseCase;
  late final JoinGroupUseCase _joinGroupUseCase;

  @override
  GroupSearchState build() {
    _searchGroupsUseCase = ref.watch(searchGroupsUseCaseProvider);
    _joinGroupUseCase = ref.watch(joinGroupUseCaseProvider);

    // 현재 사용자 정보를 auth provider에서 가져옴
    final currentUser = ref.watch(currentUserProvider);

    // 🔄 페이지 재진입 시에도 상태 복원
    _restoreStateIfNeeded();

    return GroupSearchState(
      currentMember: currentUser,
    );
  }

  /// 페이지 재진입 시 상태 복원
  Future<void> _restoreStateIfNeeded() async {
    // 이미 데이터가 있으면 복원 안 함
    if (state.recentSearches.isNotEmpty) {
      return;
    }

    // 검색어 히스토리 로드
    await _loadSearchHistory();
  }

  /// 검색어 히스토리 로드
  Future<void> _loadSearchHistory() async {
    try {
      final recentSearches = await SearchHistoryService.getRecentSearches();

      state = state.copyWith(recentSearches: recentSearches);
    } catch (e) {
      AppLogger.error('그룹 검색어 히스토리 로드 실패', tag: 'GroupSearch', error: e);
    }
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
        await _handleSearch(query);
        break;

      case OnClearSearch():
        // ⭐ 검색 결과만 지우고 히스토리는 유지
        state = state.copyWith(
          query: '',
          searchResults: const AsyncValue.data([]),
        );
        break;

      case OnTapGroup(:final groupId):
        _selectGroup(groupId);
        break;

      case OnGoBack():
        // ⭐ 뒤로가기 시에도 상태 유지 (query만 초기화)
        state = state.copyWith(
          query: '',
          searchResults: const AsyncValue.data([]),
          // recentSearches는 유지!
        );
        break;

      case OnRemoveRecentSearch(:final query):
        await _removeRecentSearch(query);
        break;

      case OnClearAllRecentSearches():
        await _clearAllRecentSearches();
        break;

      case OnJoinGroup(:final groupId):
        await _joinGroup(groupId);
        break;

      case ResetSelectedGroup():
        // selectedGroup 초기화
        state = state.copyWith(selectedGroup: const AsyncData(null));
        break;

      case OnCloseDialog():
        // 다이얼로그 닫을 때 selectedGroup 초기화
        state = state.copyWith(selectedGroup: const AsyncData(null));
        break;
    }
  }

  /// 검색 실행
  Future<void> _handleSearch(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    try {
      // 1. 쿼리 상태 업데이트
      state = state.copyWith(query: trimmedQuery);

      // 2. 로딩 상태로 변경
      state = state.copyWith(searchResults: const AsyncLoading());

      // 3. UseCase를 통해 검색 수행
      final results = await _searchGroupsUseCase.execute(trimmedQuery);

      // 4. 검색 결과 반영
      state = state.copyWith(searchResults: results);

      // 5. 최근 검색어에 추가
      await _addToSearchHistory(trimmedQuery);
    } catch (e) {
      // 검색 실패 시 에러 상태로 변경
      state = state.copyWith(
        searchResults: AsyncError(e, StackTrace.current),
      );
    }
  }

  /// 검색어 히스토리에 추가
  Future<void> _addToSearchHistory(String query) async {
    try {
      // 그룹 카테고리로 검색어 추가
      await SearchHistoryService.addSearchTerm(
        query,
      );

      // ⭐ 즉시 상태 업데이트 (로컬에서 빠르게 반영)
      _updateLocalHistory(query);

      // 백그라운드에서 전체 히스토리 다시 로드
      _loadSearchHistory();
    } catch (e) {
      AppLogger.error('그룹 검색어 히스토리 추가 실패', tag: 'GroupSearch', error: e);
    }
  }

  /// 로컬 상태에서 빠르게 히스토리 업데이트
  void _updateLocalHistory(String query) {
    final updatedRecent = [...state.recentSearches];

    // 기존에 있으면 제거
    updatedRecent.remove(query);

    // 맨 앞에 추가
    updatedRecent.insert(0, query);

    // 최대 10개까지만 유지
    if (updatedRecent.length > 10) {
      updatedRecent.removeRange(10, updatedRecent.length);
    }

    state = state.copyWith(recentSearches: updatedRecent);
  }

  /// 특정 검색어 삭제
  Future<void> _removeRecentSearch(String query) async {
    try {
      // SharedPreferences에서 삭제
      await SearchHistoryService.removeSearchTerm(
        query,
      );

      // 상태에서도 즉시 제거
      final updatedSearches = [...state.recentSearches]..remove(query);
      state = state.copyWith(recentSearches: updatedSearches);
    } catch (e) {
      AppLogger.error('그룹 검색어 삭제 실패', tag: 'GroupSearch', error: e);
      // 실패 시 다시 로드하여 동기화
      await _loadSearchHistory();
    }
  }

  /// 모든 검색어 삭제
  Future<void> _clearAllRecentSearches() async {
    try {
      // SharedPreferences 전체 삭제
      await SearchHistoryService.clearAllSearches();

      // 상태에서도 전체 삭제
      state = state.copyWith(recentSearches: []);
    } catch (e) {
      AppLogger.error('모든 그룹 검색어 삭제 실패', tag: 'GroupSearch', error: e);
      // 실패 시 다시 로드하여 동기화
      await _loadSearchHistory();
    }
  }

  /// 🔧 수동으로 상태 새로고침 (필요 시 호출)
  Future<void> refreshSearchHistory() async {
    await _loadSearchHistory();
  }
}