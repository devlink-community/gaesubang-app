import 'package:devlink_mobile_app/group/presentation/group_timer/group_timer_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/group_timer_notifier.dart';
import 'package:devlink_mobile_app/group/presentation/group_timer/group_timer_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GroupTimerScreenRoot extends ConsumerStatefulWidget {
  const GroupTimerScreenRoot({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupTimerScreenRoot> createState() =>
      _GroupTimerScreenRootState();
}

class _GroupTimerScreenRootState extends ConsumerState<GroupTimerScreenRoot> {
  @override
  void initState() {
    super.initState();

    // 초기 그룹 ID 설정 및 데이터 로드
    Future.microtask(() {
      final notifier = ref.read(groupTimerNotifierProvider.notifier);
      notifier.onAction(GroupTimerAction.setGroupId(widget.groupId));
    });
  }

  @override
  Widget build(BuildContext context) {
    // 상태 구독
    final state = ref.watch(groupTimerNotifierProvider);
    final notifier = ref.read(groupTimerNotifierProvider.notifier);

    return GroupTimerScreen(
      state: state,
      onAction: (action) async {
        switch (action) {
          case NavigateToAttendance():
            // 출석부(캘린더) 화면으로 이동
            context.push('/group/${widget.groupId}/attendance');

          case NavigateToSettings():
            // 그룹 설정 화면으로 이동
            context.push('/group/${widget.groupId}/settings');

          case NavigateToUserProfile(:final userId):
            // 사용자 프로필 화면으로 이동
            context.push('/user/$userId/profile');

          default:
            // 기타 액션은 Notifier에 위임
            await notifier.onAction(action);
        }
      },
    );
  }
}
