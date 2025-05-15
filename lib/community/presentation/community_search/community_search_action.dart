// lib/community/presentation/community_list_search/community_search_action.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'community_search_action.freezed.dart';

@freezed
sealed class CommunitySearchAction with _$CommunitySearchAction {
  const factory CommunitySearchAction.onSearch(String query) = OnSearch;
  const factory CommunitySearchAction.onTapPost(String postId) = OnTapPost;
  const factory CommunitySearchAction.onClearSearch() = OnClearSearch;
  const factory CommunitySearchAction.onGoBack() = OnGoBack;

  const factory CommunitySearchAction.onRemoveRecentSearch(String query) =
      OnRemoveRecentSearch;
  const factory CommunitySearchAction.onClearAllRecentSearches() =
      OnClearAllRecentSearches;
}