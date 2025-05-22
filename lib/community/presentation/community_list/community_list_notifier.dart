// lib/community/presentation/community_list/community_list_notifier.dart
import 'dart:async';

import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/domain/usecase/load_post_list_use_case.dart';
import 'package:devlink_mobile_app/community/module/community_di.dart';
import 'package:devlink_mobile_app/community/module/util/community_tab_type_enum.dart';
import 'package:devlink_mobile_app/community/presentation/community_list/community_list_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_list/community_list_state.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_notifier.dart';
import 'package:devlink_mobile_app/core/event/app_event.dart';
import 'package:devlink_mobile_app/core/event/app_event_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_list_notifier.g.dart';

@riverpod
class CommunityListNotifier extends _$CommunityListNotifier {
  @override
  CommunityListState build() {
    _loadPostListUseCase = ref.watch(loadPostListUseCaseProvider);

    // 글쓰기 완료 감지하여 자동 갱신
    ref.listen(
      communityWriteNotifierProvider.select((state) => state.createdPostId),
      (previous, current) {
        if (previous == null && current != null) {
          Future.microtask(() => _fetch());
        }
      },
    );

    // 앱 이벤트 리스너 추가 - 게시글/댓글 변경 감지
    ref.listen(appEventNotifierProvider, (previous, current) {
      if (previous != current) {
        // 게시글 관련 이벤트가 있으면 목록 갱신
        final hasPostEvents = current.any(
          (event) =>
              event is PostLiked ||
              event is PostBookmarked ||
              event is CommentAdded ||
              event is PostUpdated ||
              event is PostDeleted,
        );

        if (hasPostEvents) {
          debugPrint('🔄 CommunityListNotifier: 게시글 액션 이벤트 감지, 목록 갱신');
          Future.microtask(() => _fetch());
        }
      }
    });

    return const CommunityListState(currentTab: CommunityTabType.newest);
  }

  late final LoadPostListUseCase _loadPostListUseCase;

  /// 원격 새로고침
  Future<void> _fetch() async {
    state = state.copyWith(postList: const AsyncLoading());

    try {
      final result = await _loadPostListUseCase.execute();

      // switch-case 패턴 사용
      switch (result) {
        case AsyncData(:final value):
          final sortedPosts = _applySort(value, state.currentTab);
          state = state.copyWith(postList: AsyncData(sortedPosts));

        case AsyncError(:final error, :final stackTrace):
          state = state.copyWith(postList: AsyncError(error, stackTrace));

        case AsyncLoading():
          break;
      }
    } catch (e) {
      state = state.copyWith(postList: AsyncError(e, StackTrace.current));
    }
  }

  /// 탭 변경·수동 새로고침 등 외부 Action 진입점
  Future<void> onAction(CommunityListAction action) async {
    switch (action) {
      case Refresh():
        await _fetch();

      case ChangeTab(:final tab):
        state = state.copyWith(currentTab: tab);
        await _fetch();

      case TapSearch():
      case TapWrite():
      case TapPost():
        break;
    }
  }

  List<Post> _applySort(List<Post> list, CommunityTabType tab) {
    switch (tab) {
      case CommunityTabType.popular:
        final sorted = [...list]..sort(
          (a, b) => b.likeCount.compareTo(a.likeCount),
        );

        return sorted;

      case CommunityTabType.newest:
        final sorted = [...list]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return sorted;
    }
  }

  Future<void> loadInitialData() async {
    await _fetch();
  }
}
