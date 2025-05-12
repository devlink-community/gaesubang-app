import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'group_search_state.freezed.dart';

@freezed
class GroupSearchState with _$GroupSearchState {
  const GroupSearchState({
    this.query = '',
    this.searchResults = const AsyncValue.data(<Group>[]),
    this.recentSearches = const <String>[],
  });

  @override
  final String query;
  @override
  final AsyncValue<List<Group>> searchResults;
  @override
  final List<String> recentSearches;
}
