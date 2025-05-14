// lib/community/presentation/community_list_search/community_search_screen_root.dart
import 'package:devlink_mobile_app/community/presentation/community_search/community_search_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_search/community_search_notifier.dart';
import 'package:devlink_mobile_app/community/presentation/community_search/community_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CommunitySearchScreenRoot extends ConsumerWidget {
  const CommunitySearchScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communitySearchNotifierProvider);
    final notifier = ref.watch(communitySearchNotifierProvider.notifier);

    return CommunitySearchScreen(
      state: state,
      onAction: (action) {
        switch (action) {
          case OnGoBack():
            context.pop();
          case OnTapPost(:final postId):
            context.push('/community/$postId');
          default:
            notifier.onAction(action);
        }
      },
    );
  }
}
