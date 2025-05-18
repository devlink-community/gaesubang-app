import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../auth/domain/model/member.dart';

part 'group_search_state.freezed.dart';

@freezed
class GroupSearchState with _$GroupSearchState {
  const GroupSearchState({
    this.query = '',
    this.searchResults = const AsyncValue.data(<Group>[]),
    this.recentSearches = const <String>[],
    this.selectedGroup = const AsyncValue.data(null),
    this.joinGroupResult = const AsyncValue.data(null),
    this.currentMember,
  });

  @override
  final String query;
  @override
  final AsyncValue<List<Group>> searchResults;
  @override
  final List<String> recentSearches;
  final AsyncValue<Group?> selectedGroup;
  final AsyncValue<void> joinGroupResult;
  final Member? currentMember;
}
