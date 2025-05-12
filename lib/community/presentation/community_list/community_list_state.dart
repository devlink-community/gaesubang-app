// lib/community/presentation/community_list/community_list_state.dart

import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/module/util/community_tab_type_enum.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'community_list_state.freezed.dart';

@freezed
class CommunityListState with _$CommunityListState {
  const CommunityListState({
    this.postList = const AsyncValue<List<Post>>.loading(),
    this.currentTab = CommunityTabType.popular,
  });

  @override
  final AsyncValue<List<Post>> postList;
  @override
  final CommunityTabType currentTab;
}