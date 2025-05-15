// lib/community/presentation/community_list/community_list_screen_root.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'community_list_action.dart';
import 'community_list_notifier.dart';
import 'community_list_screen.dart';

class CommunityListScreenRoot extends ConsumerWidget {
  const CommunityListScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityListNotifierProvider);
    final notifier = ref.watch(communityListNotifierProvider.notifier);

    return CommunityListScreen(
      state: state,
      onAction: (action) async {
        switch (action) {
          case TapPost(:final postId):
            await context.push('/community/$postId');
            
          case TapSearch():
            await context.push('/community/search');
            
          case TapWrite():
            // 게시글 작성 화면으로 이동하고, 결과(생성된 게시글 ID)를 받아옴
            final result = await context.push('/community/write');
            
            // 작성 완료 후 돌아왔을 때, 새로고침 액션 실행
            if (result != null) {
              await notifier.onAction(const CommunityListAction.refresh());
            }
            
          default:
            await notifier.onAction(action);
        }
      },
    );
  }
}