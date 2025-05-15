import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/home/domain/model/notice.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'home_state.freezed.dart';

@freezed
class HomeState with _$HomeState {
  const HomeState({
    this.notices = const AsyncLoading(),
    this.userGroups = const AsyncLoading(),
    this.popularPosts = const AsyncLoading(),
  });

  final AsyncValue<List<Notice>> notices;
  final AsyncValue<List<Group>> userGroups;
  final AsyncValue<List<Post>> popularPosts;
}
