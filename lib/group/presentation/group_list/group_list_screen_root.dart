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

    // 그룹 참여 결과를 관찰하고 성공 시 그룹 상세 페이지로 이동
    ref.listen(
      groupListNotifierProvider.select((value) => value.joinGroupResult),
      (previous, next) {
        if (previous is AsyncLoading && next is AsyncData) {
          final selectedGroup = state.selectedGroup;
          if (selectedGroup is AsyncData && selectedGroup.value != null) {
            Navigator.of(context).pop(); // 다이얼로그 닫기
            context.push('/group/${selectedGroup.value!.id}'); // 상세 페이지로 이동
          }
        } else if (next is AsyncError) {
          // 에러 처리 (스낵바 등)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('참여 실패: ${next.error}')));
        }
      },
    );

    return GroupListScreen(
      state: state,
      onAction: (action) {
        switch (action) {
          case OnTapSearch():
            context.push('/search');
          case OnTapCreateGroup():
            context.push('/group/create');
          case OnCloseDialog():
            Navigator.of(context).pop();
          case OnTapGroup() || OnJoinGroup() || OnLoadGroupList():
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
      builder: (context) {
        return GroupJoinDialog(
          group: group,
          onAction: (action) => notifier.onAction(action),
        );
      },
    );
  }
}
