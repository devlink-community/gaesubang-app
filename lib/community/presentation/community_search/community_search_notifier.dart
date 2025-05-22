import 'package:devlink_mobile_app/community/domain/usecase/search_posts_use_case.dart';
import 'package:devlink_mobile_app/community/module/community_di.dart';
import 'package:devlink_mobile_app/community/presentation/community_search/community_search_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_search/community_search_state.dart';
import 'package:devlink_mobile_app/core/service/search_history_item.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_search_notifier.g.dart';

@Riverpod(keepAlive: true)
class CommunitySearchNotifier extends _$CommunitySearchNotifier {
  late final SearchPostsUseCase _searchPostsUseCase;

  @override
  CommunitySearchState build() {
    _searchPostsUseCase = ref.watch(searchPostsUseCaseProvider);

    // 🔄 페이지 재진입 시에도 상태 복원
    _restoreStateIfNeeded();

    return const CommunitySearchState();
  }

  /// 페이지 재진입 시 상태 복원
  Future<void> _restoreStateIfNeeded() async {
    // 이미 데이터가 있으면 복원 안 함
    if (state.recentSearches.isNotEmpty || state.popularSearches.isNotEmpty) {
      return;
    }

    // 검색어 히스토리 로드
    await _loadSearchHistory();
  }

  /// 검색어 히스토리 로드 (최근 + 인기)
  Future<void> _loadSearchHistory() async {
    try {
      // 로딩 상태 표시
      state = state.copyWith(isLoading: true);

      // 병렬로 최근 검색어와 인기 검색어 로드
      final results = await Future.wait([
        SearchHistoryService.getRecentSearches(
          category: SearchCategory.community,
          filter: state.currentFilter,
          limit: 8,
        ),
      ]);

      final recentSearches = results[0];
      final popularSearches = results[1];

      // 상태 업데이트
      state = state.copyWith(
        recentSearches: recentSearches,
        popularSearches: popularSearches,
        isLoading: false,
      );
    } catch (e) {
      print('검색어 히스토리 로드 실패: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> onAction(CommunitySearchAction action) async {
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

      case OnTapPost(:final postId):
        // Root에서 처리할 네비게이션 액션
        break;

      case OnGoBack():
        // ⭐ 뒤로가기 시에도 상태 유지 (query만 초기화)
        state = state.copyWith(
          query: '',
          searchResults: const AsyncValue.data([]),
          // recentSearches, popularSearches는 유지!
        );
        break;

      case OnRemoveRecentSearch(:final query):
        await _removeRecentSearch(query);
        break;

      case OnClearAllRecentSearches():
        await _clearAllRecentSearches();
        break;
    }
  }

  /// 검색 실행 (빈도수 추적 포함)
  Future<void> _handleSearch(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    try {
      // 1. 쿼리 상태 업데이트
      state = state.copyWith(query: trimmedQuery);

      // 2. 로딩 상태로 변경
      state = state.copyWith(searchResults: const AsyncLoading());

      // 3. UseCase를 통해 검색 수행
      final results = await _searchPostsUseCase.execute(trimmedQuery);

      // 4. 검색 결과 반영
      state = state.copyWith(searchResults: results);

      // 5. 검색어 히스토리에 추가 (빈도수 자동 증가)
      await _addToSearchHistory(trimmedQuery);
    } catch (e) {
      // 검색 실패 시 에러 상태로 변경
      state = state.copyWith(
        searchResults: AsyncError(e, StackTrace.current),
      );
    }
  }

  /// 검색어 히스토리에 추가 (빈도수 관리)
  Future<void> _addToSearchHistory(String query) async {
    try {
      // 커뮤니티 카테고리로 검색어 추가 (빈도수 자동 관리)
      await SearchHistoryService.addSearchTerm(
        query,
        category: SearchCategory.community,
      );

      // ⭐ 즉시 상태 업데이트 (로컬에서 빠르게 반영)
      _updateLocalHistory(query);

      // 백그라운드에서 전체 히스토리 다시 로드
      _loadSearchHistory();
    } catch (e) {
      print('검색어 히스토리 추가 실패: $e');
    }
  }

  /// 로컬 상태에서 빠르게 히스토리 업데이트
  void _updateLocalHistory(String query) {
    final updatedRecent = [...state.recentSearches];

    // 기존에 있으면 제거
    updatedRecent.remove(query);

    // 맨 앞에 추가
    updatedRecent.insert(0, query);

    // 최대 8개까지만 유지
    if (updatedRecent.length > 8) {
      updatedRecent.removeRange(8, updatedRecent.length);
    }

    state = state.copyWith(recentSearches: updatedRecent);
  }

  /// 특정 검색어 삭제
  Future<void> _removeRecentSearch(String query) async {
    try {
      // SharedPreferences에서 삭제
      await SearchHistoryService.removeSearchTerm(
        query,
        category: SearchCategory.community,
      );

      // 상태에서도 즉시 제거
      final updatedRecentSearches = [...state.recentSearches]..remove(query);
      final updatedPopularSearches = [...state.popularSearches]..remove(query);

      state = state.copyWith(
        recentSearches: updatedRecentSearches,
        popularSearches: updatedPopularSearches,
      );
    } catch (e) {
      print('검색어 삭제 실패: $e');
      // 실패 시 다시 로드하여 동기화
      await _loadSearchHistory();
    }
  }

  /// 모든 검색어 삭제
  Future<void> _clearAllRecentSearches() async {
    try {
      // SharedPreferences 전체 삭제
      await SearchHistoryService.clearAllSearches(
        category: SearchCategory.community,
      );

      // 상태에서도 전체 삭제
      state = state.copyWith(
        recentSearches: [],
        popularSearches: [],
      );
    } catch (e) {
      print('모든 검색어 삭제 실패: $e');
      // 실패 시 다시 로드하여 동기화
      await _loadSearchHistory();
    }
  }

  /// 검색어 필터 변경 (최신순/빈도순/가나다순)
  Future<void> changeSearchFilter(SearchFilter filter) async {
    try {
      state = state.copyWith(currentFilter: filter);

      final filteredSearches = await SearchHistoryService.getRecentSearches(
        category: SearchCategory.community,
        filter: filter,
        limit: 8,
      );

      state = state.copyWith(recentSearches: filteredSearches);
    } catch (e) {
      print('검색어 필터 변경 실패: $e');
    }
  }

  /// 🔧 수동으로 상태 새로고침 (필요 시 호출)
  Future<void> refreshSearchHistory() async {
    await _loadSearchHistory();
  }

  /// 📊 검색 통계 조회
  Future<Map<String, dynamic>> getSearchStatistics() async {
    try {
      return await SearchHistoryService.getSearchStatistics(
        category: SearchCategory.community,
      );
    } catch (e) {
      print('검색 통계 조회 실패: $e');
      return {};
    }
  }
}
