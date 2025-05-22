// lib/community/presentation/community_search/community_search_screen_root.dart
import 'package:devlink_mobile_app/community/presentation/community_search/community_search_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_search/community_search_notifier.dart';
import 'package:devlink_mobile_app/community/presentation/community_search/community_search_screen.dart';
import 'package:devlink_mobile_app/community/presentation/community_search/community_search_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CommunitySearchScreenRoot extends ConsumerWidget {
  const CommunitySearchScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communitySearchNotifierProvider);
    final notifier = ref.watch(communitySearchNotifierProvider.notifier);

    // ⭐ 페이지 진입 시 상태 새로고침 (필요한 경우)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureHistoryLoaded(notifier, state);
    });

    return CommunitySearchScreen(
      state: state,
      onAction: (action) {
        switch (action) {
          case OnGoBack():
            // ⭐ 뒤로가기 시 상태는 유지하되 화면만 이동
            notifier.onAction(action); // 쿼리 초기화
            context.pop();

          case OnTapPost(:final postId):
            context.push('/community/$postId');

          default:
            // 나머지 액션은 Notifier에서 처리
            notifier.onAction(action);
        }
      },
    );
  }

  /// 히스토리가 로드되지 않은 경우 강제 로드
  void _ensureHistoryLoaded(
    CommunitySearchNotifier notifier,
    CommunitySearchState state,
  ) {
    // 검색어 히스토리가 비어있고 로딩 중이 아닌 경우 새로고침
    if (state.recentSearches.isEmpty &&
        state.popularSearches.isEmpty &&
        !state.isLoading) {
      Future.microtask(() {
        notifier.refreshSearchHistory();
      });
    }
  }
}
