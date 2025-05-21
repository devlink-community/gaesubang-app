// lib/community/presentation/community_detail/community_detail_screen_root.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_notifier.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_screen.dart';
import 'package:devlink_mobile_app/core/auth/auth_provider.dart';
import 'package:devlink_mobile_app/core/event/app_event.dart';
import 'package:devlink_mobile_app/core/event/app_event_notifier.dart';

class CommunityDetailScreenRoot extends ConsumerWidget {
  const CommunityDetailScreenRoot({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 상태 및 notifier 구독
    final state = ref.watch(communityDetailNotifierProvider(postId));
    final notifier = ref.read(communityDetailNotifierProvider(postId).notifier);

    // 현재 로그인한 사용자 정보 가져오기
    final currentUser = ref.read(currentUserProvider);

    // appEventNotifier 리스닝 (게시글 삭제 이벤트 감지)
    ref.listen<List<AppEvent>>(appEventNotifierProvider, (_, events) {
      for (final event in events) {
        // 게시글 삭제 이벤트가 발생하면 목록 화면으로 이동
        if (event is PostDeleted && event.postId == postId) {
          if (context.mounted) {
            // 성공 메시지 표시
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('게시글이 삭제되었습니다')));

            // 목록 화면으로 이동하며 refresh 플래그 직접 전달
            context.go('/community');

            // 이벤트 발행 (모든 관련 컴포넌트에게 알림)
            ref
                .read(appEventNotifierProvider.notifier)
                .emit(const AppEvent.refreshCommunity());
          }
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
}
