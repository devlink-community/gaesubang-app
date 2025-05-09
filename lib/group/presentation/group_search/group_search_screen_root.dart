// lib/group/presentation/group_search/group_search_screen_root.dart
import 'package:devlink_mobile_app/group/presentation/group_search/group_search_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_search/group_search_notifier.dart';
import 'package:devlink_mobile_app/group/presentation/group_search/group_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GroupSearchScreenRoot extends ConsumerWidget {
  const GroupSearchScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupSearchNotifierProvider);
    final notifier = ref.watch(groupSearchNotifierProvider.notifier);

    return GroupSearchScreen(
      state: state,
      onAction: (action) {
        switch (action) {
          case OnGoBack():
            context.pop();
          case OnTapGroup(:final groupId):
            context.push('/group/$groupId');
          default:
            notifier.onAction(action);
        }
      },
    );
  }
}
