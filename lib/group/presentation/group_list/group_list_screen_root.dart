import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/group/presentation/component/group_join_dialog.dart';
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

    ref.listen(
      groupListNotifierProvider.select((value) => value.selectedGroup),
      (previous, next) {
        if (next is AsyncData && next.value != null) {
          final group = next.value!;

          // 현재 사용자가 이미 가입된 그룹인지 확인
          final isJoined = notifier.isCurrentMemberInGroup(group);

          if (isJoined) {
            // 이미 가입된 그룹이면 바로 상세 페이지로 이동
            context.push('/group/${group.id}');

            // selectedGroup 초기화
            notifier.onAction(const GroupListAction.resetSelectedGroup());
          } else {
            // 가입되지 않은 그룹이면 가입 다이얼로그 표시
            _showGroupDialog(context, group, notifier);
          }
        }
      },
    );

    ref.listen(
      groupListNotifierProvider.select((value) => value.joinGroupResult),
      (previous, next) {
        if (previous is AsyncLoading) {
          if (next is AsyncData) {
            final selectedGroup = state.selectedGroup;
            if (selectedGroup is AsyncData && selectedGroup.value != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '그룹에 성공적으로 참여했습니다!',
                    style: TextStyle(color: AppColorStyles.white),
                  ),
                  backgroundColor: AppColorStyles.primary100,
                ),
              );
              final groupId = selectedGroup.value!.id;
              context.push('/group/$groupId');
            }
          } else if (next is AsyncError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('참여 실패: ${next.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );

    return GroupListScreen(
      state: state,
      onAction: (action) {
        switch (action) {
          case OnTapSearch():
            context.push('/group/search');
          case OnTapCreateGroup():
            context.push('/group/create');
          case OnCloseDialog():
            // 다이얼로그 닫을 때 selectedGroup 초기화
            notifier.onAction(const GroupListAction.resetSelectedGroup());
            Navigator.of(context).pop();
          case OnTapSort():
            // 이 액션은 GroupListScreen에서 처리되므로 여기서는 무시
            break;
          case OnChangeSortType():
            // 정렬 타입 변경 액션 처리 - 바로 notifier에 전달
            notifier.onAction(action);
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
            switch (action) {
              case OnCloseDialog():
                // 다이얼로그 닫을 때 selectedGroup 초기화
                notifier.onAction(const GroupListAction.resetSelectedGroup());
                Navigator.of(context).pop();

              case OnJoinGroup():
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '그룹 참여 중...',
                      style: TextStyle(color: AppColorStyles.white),
                    ),
                    duration: Duration(seconds: 1),
                  ),
                );
                notifier.onAction(action);

              default:
                notifier.onAction(action);
            }
          },
        );
      },
    );
  }
}
