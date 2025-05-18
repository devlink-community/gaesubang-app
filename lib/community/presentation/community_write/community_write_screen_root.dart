// lib/community/presentation/community_write/community_write_screen_root.dart
import 'package:devlink_mobile_app/community/module/util/community_tab_type_enum.dart';
import 'package:devlink_mobile_app/community/presentation/community_list/community_list_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_list/community_list_notifier.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_notifier.dart';
import 'package:devlink_mobile_app/community/presentation/community_write/community_write_screen.dart';

class CommunityWriteScreenRoot extends ConsumerStatefulWidget {
  const CommunityWriteScreenRoot({super.key});

  @override
  ConsumerState<CommunityWriteScreenRoot> createState() =>
      _CommunityWriteScreenRootState();
}

class _CommunityWriteScreenRootState
    extends ConsumerState<CommunityWriteScreenRoot> {
  @override
  void initState() {
    super.initState();

    ref.listen<CommunityWriteState>(communityWriteNotifierProvider, (
      previous,
      current,
    ) {
      // 이전 상태에는 ID가 없고, 현재 상태에는 ID가 있는 경우
      if (previous?.createdPostId == null && current.createdPostId != null) {
        print('Post created, directly refreshing list');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Community List Notifier 직접 접근
          final communityListNotifier = ref.read(
            communityListNotifierProvider.notifier,
          );

          // 직접 새로고침 및 탭 변경 호출
          communityListNotifier.onAction(const CommunityListAction.refresh());
          communityListNotifier.onAction(
            const CommunityListAction.changeTab(CommunityTabType.newest),
          );

          // 목록 화면으로 이동
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/community');
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityWriteNotifierProvider);
    final notifier = ref.watch(communityWriteNotifierProvider.notifier);

    return CommunityWriteScreen(state: state, onAction: notifier.onAction);
  }
}
