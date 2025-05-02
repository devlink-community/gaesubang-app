import 'package:flutter/material.dart';
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
            context.push('/community/$postId');                             // 상세 화면 경로 예시
          case TapSearch():
            context.push('/community/search');
          case TapWrite():
            context.push('/community/write');
          default:
            await notifier.onAction(action);
        }
      },
    );
  }
}
