// lib/map/presentation/group_map_screen_root.dart
import 'package:devlink_mobile_app/map/presentation/group_map_action.dart';
import 'package:devlink_mobile_app/map/presentation/group_map_notifier.dart';
import 'package:devlink_mobile_app/map/presentation/group_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GroupMapScreenRoot extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const GroupMapScreenRoot({
    super.key,
    required this.groupId,
    this.groupName = '그룹 위치',
  });

  @override
  ConsumerState<GroupMapScreenRoot> createState() => _GroupMapScreenRootState();
}

class _GroupMapScreenRootState extends ConsumerState<GroupMapScreenRoot> {
  @override
  void initState() {
    super.initState();

    // 화면 초기화 지연 처리
    Future.microtask(() {
      ref
          .read(groupMapNotifierProvider.notifier)
          .onAction(
            GroupMapAction.initialize(widget.groupId, widget.groupName),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupMapNotifierProvider);
    final notifier = ref.read(groupMapNotifierProvider.notifier);

    return GroupMapScreen(
      state: state,
      onAction: (action) {
        switch (action) {
          case NavigateToMemberProfile(:final memberId):
            // 멤버 프로필 화면으로 이동
            context.push('/user/$memberId/profile');
          default:
            // 기타 액션은 Notifier에 위임
            notifier.onAction(action);
        }
      },
    );
  }
}
