// lib/community/presentation/community_write/community_write_screen_root.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_notifier.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_screen.dart';

class CommunityWriteScreenRoot extends ConsumerWidget {
  const CommunityWriteScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityWriteNotifierProvider);
    final notifier = ref.read(communityWriteNotifierProvider.notifier);

    return CommunityWriteScreen(state: state, onAction: notifier.onAction);
  }
}
