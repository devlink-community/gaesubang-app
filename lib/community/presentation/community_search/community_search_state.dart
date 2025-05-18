// lib/community/presentation/community_list_search/community_search_state.dart
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'community_search_state.freezed.dart';

@freezed
class CommunitySearchState with _$CommunitySearchState {
  const CommunitySearchState({
    this.query = '',
    this.searchResults = const AsyncValue.data(<Post>[]),
    this.recentSearches = const <String>[],
  });

  @override
  final String query;
  @override
  final AsyncValue<List<Post>> searchResults;
  @override
  final List<String> recentSearches;
}