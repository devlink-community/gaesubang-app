// lib/community/presentation/community_search/community_search_notifier.dart
import 'package:devlink_mobile_app/community/domain/usecase/search_posts_use_case.dart';
import 'package:devlink_mobile_app/community/module/community_di.dart';
import 'package:devlink_mobile_app/community/presentation/community_search/community_search_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_search/community_search_state.dart';
import 'package:devlink_mobile_app/core/service/search_history_item.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_search_notifier.g.dart';

@riverpod
class CommunitySearchNotifier extends _$CommunitySearchNotifier {
  late final SearchPostsUseCase _searchPostsUseCase;

  @override
  CommunitySearchState build() {
    _searchPostsUseCase = ref.watch(searchPostsUseCaseProvider);

    // 앱 시작 시 최근 검색어 및 인기 검색어 로드
    _loadSearchHistory();

    return const CommunitySearchState();
  }

  /// 검색어 히스토리 로드 (최근 + 인기)
  Future<void> _loadSearchHistory() async {
    try {
      // 병렬로 최근 검색어와 인기 검색어 로드
      final results = await Future.wait([
        SearchHistoryService.getRecentSearches(
          category: SearchCategory.community,
          filter: SearchFilter.recent,
          limit: 8,
        ),
        SearchHistoryService.getPopularSearches(
          category: SearchCategory.community,
          limit: 5,
        ),
      ]);

      final recentSearches = results[0];
      final popularSearches = results[1];

      // 상태 업데이트
      state = state.copyWith(
        recentSearches: recentSearches,
        popularSearches: popularSearches,
      );
    } catch (e) {
      print('검색어 히스토리 로드 실패: $e');
      // 실패해도 앱은 정상 동작하도록 빈 리스트 유지
    }
  }

  Future<void> onAction(CommunitySearchAction action) async {
    switch (action) {
      case OnSearch(:final query):
        await _handleSearch(query);
        break;

      case OnClearSearch():
        state = state.copyWith(
          query: '',
          searchResults: const AsyncValue.data([]),
        );
        break;

      case OnTapPost():
        // Root에서 처리할 네비게이션 액션
        break;

      case OnGoBack():
        // Root에서 처리할 네비게이션 액션
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

      // 업데이트된 검색어 목록을 다시 로드하여 상태 동기화
      await _loadSearchHistory();
    } catch (e) {
      print('검색어 히스토리 추가 실패: $e');
      // 실패해도 검색 기능에는 영향 없음
    }
  }

  /// 특정 검색어 삭제
  Future<void> _removeRecentSearch(String query) async {
    try {
      // SharedPreferences에서 삭제
      await SearchHistoryService.removeSearchTerm(
        query,
        category: SearchCategory.community,
      );

      // 상태에서도 제거
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

  /// 인기 검색어 새로고침
  Future<void> refreshPopularSearches() async {
    try {
      final popularSearches = await SearchHistoryService.getPopularSearches(
        category: SearchCategory.community,
        limit: 5,
      );

      state = state.copyWith(popularSearches: popularSearches);
    } catch (e) {
      print('인기 검색어 새로고침 실패: $e');
    }
  }

  /// 검색 통계 조회
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

  /// 검색어 필터 변경 (최신순/빈도순/가나다순)
  Future<void> changeSearchFilter(SearchFilter filter) async {
    try {
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

  /// 검색어 데이터 백업
  Future<Map<String, dynamic>> backupSearchData() async {
    try {
      return await SearchHistoryService.exportAllData();
    } catch (e) {
      print('검색어 데이터 백업 실패: $e');
      return {};
    }
  }

  /// 검색어 데이터 복원
  Future<void> restoreSearchData(Map<String, dynamic> backupData) async {
    try {
      await SearchHistoryService.importAllData(backupData);
      await _loadSearchHistory(); // 복원 후 상태 새로고침
    } catch (e) {
      print('검색어 데이터 복원 실패: $e');
    }
  }
}
