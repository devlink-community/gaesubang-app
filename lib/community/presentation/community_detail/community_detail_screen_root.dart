// lib/community/presentation/community_detail/community_detail_screen_root.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_notifier.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_screen.dart';

class CommunityDetailScreenRoot extends ConsumerWidget {
  const CommunityDetailScreenRoot({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1️⃣ 상태(State) 구독
    final state = ref.watch(
      communityDetailNotifierProvider(postId), // 반환형: CommunityDetailState
    );

    // 2️⃣ Notifier 메서드 호출용 핸들
    final notifier = ref.read(communityDetailNotifierProvider(postId).notifier);

    return CommunityDetailScreen(
      state: state, // 그대로 전달
      onAction: notifier.onAction, // 액션 위임
    );
  }
}