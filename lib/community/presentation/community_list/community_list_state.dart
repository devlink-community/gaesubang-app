import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/module/util/%08community_tab_type_enum.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'community_list_state.freezed.dart';

@freezed
abstract class CommunityListState with _$CommunityListState {
  const factory CommunityListState({
    @Default(AsyncValue<List<Post>>.loading()) AsyncValue<List<Post>> postList,
    @Default(CommunityTabType.popular) CommunityTabType currentTab,
  }) = _CommunityListState;
}
