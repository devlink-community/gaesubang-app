// lib/community/presentation/community_list_search/community_search_state.dart
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/core/service/search_history_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'community_search_state.freezed.dart';

@freezed
class CommunitySearchState with _$CommunitySearchState {
  const CommunitySearchState({
    this.query = '',
    this.searchResults = const AsyncValue.data(<Post>[]),
    this.recentSearches = const <String>[],
    this.popularSearches = const <String>[], // 인기 검색어 추가
    this.currentFilter = SearchFilter.recent, // 현재 필터 상태
    this.isLoading = false, // 히스토리 로딩 상태
  });

  @override
  final String query;
  @override
  final AsyncValue<List<Post>> searchResults;
  @override
  final List<String> recentSearches;
  final List<String> popularSearches; // 인기 검색어
  final SearchFilter currentFilter; // 현재 적용된 필터
  final bool isLoading; // 히스토리 로딩 상태
}
