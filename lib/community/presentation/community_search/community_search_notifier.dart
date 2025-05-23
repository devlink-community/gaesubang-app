import 'package:devlink_mobile_app/community/domain/usecase/search_posts_use_case.dart';
import 'package:devlink_mobile_app/community/module/community_di.dart';
import 'package:devlink_mobile_app/community/presentation/community_search/community_search_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_search/community_search_state.dart';
import 'package:devlink_mobile_app/core/service/search_history_item.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
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

    AppLogger.communityInfo('CommunitySearchNotifier 초기화 완료');
    return const CommunitySearchState();
  }

  /// 페이지 재진입 시 상태 복원
  Future<void> _restoreStateIfNeeded() async {
    // 이미 데이터가 있으면 복원 안 함
    if (state.recentSearches.isNotEmpty || state.popularSearches.isNotEmpty) {
      AppLogger.debug('검색 히스토리 이미 존재 - 복원 생략');
      return;
    }

    AppLogger.debug('페이지 재진입 - 검색 상태 복원 시작');
    // 검색어 히스토리 로드
    await _loadSearchHistory();
  }

  /// 검색어 히스토리 로드 (최근 + 인기)
  Future<void> _loadSearchHistory() async {
    try {
      // 로딩 상태 표시
      state = state.copyWith(isLoading: true);
      AppLogger.info('검색 히스토리 로드 시작');

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

      AppLogger.info(
        '검색 히스토리 로드 완료: 최근 ${recentSearches.length}개, 인기 ${popularSearches.length}개',
      );
    } catch (e, st) {
      AppLogger.error('검색어 히스토리 로드 실패', error: e, stackTrace: st);
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> onAction(CommunitySearchAction action) async {
    AppLogger.debug(
      'CommunitySearchAction 수신: ${action.runtimeType}',
      tag: 'CommunitySearch',
    );

    switch (action) {
      case OnSearch(:final query):
        await _handleSearch(query);
        break;

      case OnClearSearch():
        AppLogger.info('검색 결과 초기화');
        // ⭐ 검색 결과만 지우고 히스토리는 유지
        state = state.copyWith(
          query: '',
          searchResults: const AsyncValue.data([]),
        );
        break;

      case OnTapPost(:final postId):
        AppLogger.navigation('검색 결과에서 게시글 선택: $postId');
        // Root에서 처리할 네비게이션 액션
        break;

      case OnGoBack():
        AppLogger.navigation('검색 화면 뒤로가기');
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
    if (trimmedQuery.isEmpty) {
      AppLogger.warning('빈 검색어 입력 - 검색 무시');
      return;
    }

    AppLogger.logBox('게시글 검색', '검색어: "$trimmedQuery"');

    try {
      // 1. 쿼리 상태 업데이트
      state = state.copyWith(query: trimmedQuery);

      // 2. 로딩 상태로 변경
      state = state.copyWith(searchResults: const AsyncLoading());
      AppLogger.info('검색 시작: "$trimmedQuery"');

      // 3. UseCase를 통해 검색 수행
      final result = await _searchPostsUseCase.execute(trimmedQuery);

      // 4. 검색 결과 반영
      state = state.copyWith(searchResults: result);

      // 결과 로깅
      switch (result) {
        case AsyncData(:final value):
          AppLogger.info('검색 완료: "$trimmedQuery" - ${value.length}개 결과');
          if (value.isEmpty) {
            AppLogger.warning('검색 결과 없음: "$trimmedQuery"');
          }
        case AsyncError(:final error):
          AppLogger.error('검색 실패: "$trimmedQuery"', error: error);
      }

      // 5. 검색어 히스토리에 추가 (빈도수 자동 증가)
      await _addToSearchHistory(trimmedQuery);
    } catch (e, st) {
      // 검색 실패 시 에러 상태로 변경
      state = state.copyWith(
        searchResults: AsyncError(e, StackTrace.current),
      );
      AppLogger.error('검색 중 예외 발생: "$trimmedQuery"', error: e, stackTrace: st);
    }
  }

  /// 검색어 히스토리에 추가 (빈도수 관리)
  Future<void> _addToSearchHistory(String query) async {
    try {
      AppLogger.debug('검색어 히스토리 추가: "$query"');

      // 커뮤니티 카테고리로 검색어 추가 (빈도수 자동 관리)
      await SearchHistoryService.addSearchTerm(
        query,
        category: SearchCategory.community,
      );

      // ⭐ 즉시 상태 업데이트 (로컬에서 빠르게 반영)
      _updateLocalHistory(query);

      // 백그라운드에서 전체 히스토리 다시 로드
      _loadSearchHistory();

      AppLogger.info('검색어 히스토리 추가 완료: "$query"');
    } catch (e, st) {
      AppLogger.error('검색어 히스토리 추가 실패', error: e, stackTrace: st);
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
    AppLogger.debug('로컬 검색 히스토리 업데이트: "$query" (총 ${updatedRecent.length}개)');
  }

  /// 특정 검색어 삭제
  Future<void> _removeRecentSearch(String query) async {
    AppLogger.info('검색어 삭제 요청: "$query"');

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

      AppLogger.info(
        '검색어 삭제 완료: "$query" (남은 ${updatedRecentSearches.length}개)',
      );
    } catch (e, st) {
      AppLogger.error('검색어 삭제 실패: "$query"', error: e, stackTrace: st);
      // 실패 시 다시 로드하여 동기화
      await _loadSearchHistory();
    }
  }

  /// 모든 검색어 삭제
  Future<void> _clearAllRecentSearches() async {
    AppLogger.logBox('검색 히스토리', '모든 검색어 삭제 요청');

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

      AppLogger.info('모든 검색어 삭제 완료');
    } catch (e, st) {
      AppLogger.error('모든 검색어 삭제 실패', error: e, stackTrace: st);
      // 실패 시 다시 로드하여 동기화
      await _loadSearchHistory();
    }
  }

  /// 검색어 필터 변경 (최신순/빈도순/가나다순)
  Future<void> changeSearchFilter(SearchFilter filter) async {
    AppLogger.info('검색 필터 변경: ${state.currentFilter.name} → ${filter.name}');

    try {
      state = state.copyWith(currentFilter: filter);

      final filteredSearches = await SearchHistoryService.getRecentSearches(
        category: SearchCategory.community,
        filter: filter,
        limit: 8,
      );

      state = state.copyWith(recentSearches: filteredSearches);
      AppLogger.info('검색 필터 적용 완료: ${filteredSearches.length}개 검색어');
    } catch (e, st) {
      AppLogger.error('검색어 필터 변경 실패', error: e, stackTrace: st);
    }
  }

  /// 🔧 수동으로 상태 새로고침 (필요 시 호출)
  Future<void> refreshSearchHistory() async {
    AppLogger.info('검색 히스토리 수동 새로고침');
    await _loadSearchHistory();
  }

  /// 📊 검색 통계 조회
  Future<Map<String, dynamic>> getSearchStatistics() async {
    try {
      final stats = await SearchHistoryService.getSearchStatistics(
        category: SearchCategory.community,
      );
      AppLogger.info('검색 통계 조회 완료: ${stats.keys.length}개 항목');
      return stats;
    } catch (e, st) {
      AppLogger.error('검색 통계 조회 실패', error: e, stackTrace: st);
      return {};
    }
  }
}
