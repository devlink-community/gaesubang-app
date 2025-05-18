// lib/community/presentation/community_write/community_write_screen_root.dart
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_notifier.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_screen.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CommunityWriteScreenRoot extends ConsumerWidget {
  const CommunityWriteScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 게시글 작성 완료 감지
    ref.listen<CommunityWriteState>(communityWriteNotifierProvider, (
      previous,
      current,
    ) {
      // 이전 상태에는 ID가 없고, 현재 상태에는 ID가 있는 경우 (게시글 생성 완료)
      if (previous?.createdPostId == null && current.createdPostId != null) {
        // 다음 프레임에서 실행하여 안전하게 처리
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (context.mounted) {
            try {
              // 현재 경로 확인
              final currentLocation = GoRouterState.of(context).uri.path;
              final isOnCommunityTab = currentLocation == '/community';

              // 1. 글쓰기 화면 닫기
              if (context.canPop()) {
                context.pop();
              }

              if (!isOnCommunityTab) {
                // 이동 후 CommunityListRoot에서 자동으로 갱신 감지 처리
                context.go('/community');
              }
            } catch (e) {
              print(
                'CommunityWriteRoot: Error during post-creation process: $e',
              );
            }
          }
        });
      }
    });

    final state = ref.watch(communityWriteNotifierProvider);
    final notifier = ref.watch(communityWriteNotifierProvider.notifier);

    return CommunityWriteScreen(state: state, onAction: notifier.onAction);
  }
}
