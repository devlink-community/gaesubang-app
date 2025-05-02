import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';


part 'community_list_state.freezed.dart';

enum CommunityTabType { popular, newest }

@freezed
class CommunityListState with _$CommunityListState {
  const factory CommunityListState({
    @Default(AsyncValue<List<Post>>.loading()) AsyncValue<List<Post>> postList,
    @Default(CommunityTabType.popular) CommunityTabType currentTab,
  }) = _CommunityListState;
}
