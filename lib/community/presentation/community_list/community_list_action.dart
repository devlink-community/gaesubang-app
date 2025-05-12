
import 'package:devlink_mobile_app/community/module/util/community_tab_type_enum.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'community_list_action.freezed.dart';

@freezed
sealed class CommunityListAction with _$CommunityListAction {
  const factory CommunityListAction.refresh() = Refresh;
  const factory CommunityListAction.changeTab(CommunityTabType tab) = ChangeTab;
  const factory CommunityListAction.tapPost(String postId) = TapPost;
  const factory CommunityListAction.tapSearch() = TapSearch;
  const factory CommunityListAction.tapWrite() = TapWrite;
}
