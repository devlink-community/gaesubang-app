import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_notifier.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_screen.dart';
import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/core/event/app_event.dart';
import 'package:devlink_mobile_app/core/event/app_event_notifier.dart';

class CommunityDetailScreenRoot extends ConsumerStatefulWidget {
  const CommunityDetailScreenRoot({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<CommunityDetailScreenRoot> createState() =>
      _CommunityDetailScreenRootState();
}

class _CommunityDetailScreenRootState
    extends ConsumerState<CommunityDetailScreenRoot> {
  // 이벤트 처리 상태를 추적하여 중복 처리 방지
  final Set<String> _processedEventIds = {};

  @override
  Widget build(BuildContext context) {
    // 상태 및 notifier 구독
    final state = ref.watch(communityDetailNotifierProvider(widget.postId));
    final notifier = ref.read(
      communityDetailNotifierProvider(widget.postId).notifier,
    );

    // 현재 로그인한 사용자 정보 가져오기
    final currentUser = ref.read(currentUserProvider);

    // appEventNotifier 리스닝 (게시글 삭제 이벤트 감지)
    ref.listen<List<AppEvent>>(appEventNotifierProvider, (previous, current) {
      for (final event in current) {
        // 게시글 삭제 이벤트가 발생하면 목록 화면으로 이동
        if (event is PostDeleted && event.postId == widget.postId) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('게시글이 삭제되었습니다')),
            );
            context.go('/community');
          }
          break; // 삭제 이벤트 처리 후 루프 종료
        }
      }
    });

    return CommunityDetailScreen(
      state: state,
      currentUserId: currentUser?.uid,
      onAction: (action) async {
        // 수정 액션 처리
        if (action is EditPost) {
          // 현재 게시글 데이터 가져오기
          if (state.post case AsyncData(:final value)) {
            // 수정 화면으로 이동 (게시글 데이터 전달)
            final result = await context.push(
              '/community/write',
              extra: {'post': value},
            );

            // 수정 완료 후 목록 새로고침
            if (result is Map && result['refresh'] == true) {
              notifier.onAction(const CommunityDetailAction.refresh());
            }
          }
        } else if (action is DeletePost) {
          // 삭제 액션은 notifier에서 처리 (삭제 후 이벤트 발행)
          await notifier.onAction(action);
        } else {
          // 다른 액션들은 그대로 Notifier에 위임
          await notifier.onAction(action);
        }
      },
    );
  }

  // 이벤트별 고유 ID 생성
  String _getEventId(AppEvent event) {
    return switch (event) {
      PostCreated(:final postId) => 'post_created_$postId',
      PostUpdated(:final postId) => 'post_updated_$postId',
      PostDeleted(:final postId) => 'post_deleted_$postId',
      PostLiked(:final postId) => 'post_liked_$postId',
      PostBookmarked(:final postId) => 'post_bookmarked_$postId',
      CommentAdded(:final postId, :final commentId) =>
        'comment_added_${postId}_$commentId',
      CommentLiked(:final postId, :final commentId) =>
        'comment_liked_${postId}_$commentId',
      RefreshCommunity() =>
        'refresh_community_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  @override
  void dispose() {
    // 메모리 누수 방지
    _processedEventIds.clear();
    super.dispose();
  }
}
