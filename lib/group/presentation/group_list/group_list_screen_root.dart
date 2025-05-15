import 'package:devlink_mobile_app/group/presentation/group_join_dialog.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_notifier.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../domain/model/group.dart';

class GroupListScreenRoot extends ConsumerWidget {
  const GroupListScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupListNotifierProvider);
    final notifier = ref.watch(groupListNotifierProvider.notifier);

    // 선택된 그룹을 관찰하고 변경되면 다이얼로그 표시
    ref.listen(
      groupListNotifierProvider.select((value) => value.selectedGroup),
      (previous, next) {
        if (next is AsyncData && next.value != null) {
          _showGroupDialog(context, next.value!, notifier);
        }
      },
    );

    // OnJoinGroup 액션을 직접 처리
    return GroupListScreen(
      state: state,
      onAction: (action) {
        switch (action) {
          case OnTapSearch():
            context.push('/group/search');
          case OnTapCreateGroup():
            context.push('/group/create');
          case OnCloseDialog():
            Navigator.of(context).pop();
          case OnJoinGroup(:final groupId):
            // 서버 요청은 Notifier에 위임하지만 UI 처리는 여기서
            notifier.onAction(action);

            // 다이얼로그 닫기
            Navigator.of(context).pop();

            // 바로 해당 그룹 페이지로 이동
            context.push('/group/$groupId');
          default:
            notifier.onAction(action);
        }
      },
    );
  }

  void _showGroupDialog(
    BuildContext context,
    Group group,
    GroupListNotifier notifier,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return GroupJoinDialog(
          group: group,
          onAction: (action) {
            // 다이얼로그 내에서의 액션을 여기서 바로 전달
            // 이렇게 하면 Root의 onAction으로 전달됨
            if (action is OnJoinGroup) {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              notifier.onAction(action); // 참여 요청 처리

              // 이동 처리를 직접 수행
              Future.delayed(const Duration(milliseconds: 100), () {
                if (context.mounted) {
                  context.push('/group/${(action).groupId}');
                }
              });
            } else {
              notifier.onAction(action);
            }
          },
        );
      },
    );
  }
}
