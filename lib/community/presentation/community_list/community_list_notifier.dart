// lib/community/presentation/community_list/community_list_notifier.dart

import 'dart:async';
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/domain/usecase/load_post_list_use_case.dart';
import 'package:devlink_mobile_app/community/module/community_di.dart';
import 'package:devlink_mobile_app/community/module/util/community_tab_type_enum.dart';

import 'package:devlink_mobile_app/community/presentation/community_list/community_list_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_list/community_list_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_list_notifier.g.dart';

@riverpod
class CommunityListNotifier extends _$CommunityListNotifier {
  @override
  CommunityListState build() {
    _loadPostListUseCase = ref.watch(loadPostListUseCaseProvider);
    // 비동기 로딩 → 결과 반영
    Future.microtask(_fetch);
    return const CommunityListState(); // 초기값
  }

  late final LoadPostListUseCase _loadPostListUseCase;

  /// 원격 새로고침
  Future<void> _fetch() async {
    state = state.copyWith(postList: const AsyncLoading());
    final result = await _loadPostListUseCase.execute();
    state = state.copyWith(postList: result);
  }

  /// 탭 변경·수동 새로고침 등 외부 Action 진입점
  Future<void> onAction(CommunityListAction action) async {
    switch (action) {
      case Refresh():
        await _fetch();
      case ChangeTab(:final tab):
        state = state.copyWith(
          currentTab: tab,
          postList: state.postList.maybeWhen(
            data: (list) => AsyncData(_applySort(list, tab)),
            orElse: () => state.postList,
          ),
        );
      default:
        // UI 이동 Action 은 Root 에서 처리
        break;
    }
  }

  List<Post> _applySort(List<Post> list, CommunityTabType tab) {
    switch (tab) {
      case CommunityTabType.popular:
        final sorted = [...list]..sort((a, b) => b.like.length.compareTo(a.like.length));
        return sorted;
      case CommunityTabType.newest:
        final sorted = [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return sorted;
    }
  }
}