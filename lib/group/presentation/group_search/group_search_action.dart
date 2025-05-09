// lib/group/presentation/group_search/group_search_action.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_search_action.freezed.dart';

@freezed
sealed class GroupSearchAction with _$GroupSearchAction {
  const factory GroupSearchAction.onSearch(String query) = OnSearch;
  const factory GroupSearchAction.onTapGroup(String groupId) = OnTapGroup;
  const factory GroupSearchAction.onClearSearch() = OnClearSearch;
  const factory GroupSearchAction.onGoBack() = OnGoBack;

  const factory GroupSearchAction.onRemoveRecentSearch(String query) =
      OnRemoveRecentSearch;
  const factory GroupSearchAction.onClearAllRecentSearches() =
      OnClearAllRecentSearches;
}
