// lib/group/presentation/group_search/group_search_screen_root.dart
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/presentation/component/group_join_dialog.dart';
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

    // selectedGroup 상태 리스너 추가
    ref.listen(
      groupSearchNotifierProvider.select((value) => value.selectedGroup),
      (previous, next) {
        if (next is AsyncData && next.value != null) {
          final group = next.value!;

          // 현재 사용자가 이미 그룹에 참여 중인지 확인
          final isAlreadyMember = notifier.isCurrentMemberInGroup(group);

          if (isAlreadyMember) {
            // 이미 참여 중인 경우 바로 상세 페이지로 이동
            context.push('/group/${group.id}');
            // 선택 상태 초기화 (선택적)
            notifier.onAction(const GroupSearchAction.resetSelectedGroup());
          } else {
            // 아직 참여하지 않은 경우 참여 다이얼로그 표시
            _showGroupDialog(context, group, notifier);
          }
        }
      },
    );

    // 나머지 코드는 동일...
    // joinGroupResult 상태 리스너 추가
    ref.listen(
      groupSearchNotifierProvider.select((value) => value.joinGroupResult),
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

    return GroupSearchScreen(
      state: state,
      onAction: (action) {
        switch (action) {
          case OnGoBack():
            context.pop();
          case OnTapGroup(:final groupId):
            notifier.onAction(action); // 그룹 선택 시 액션 처리
          case OnClearSearch():
          case OnSearch():
          case OnRemoveRecentSearch():
          case OnClearAllRecentSearches():
            notifier.onAction(action);
          default:
            notifier.onAction(action);
        }
      },
    );
  }

  // 그룹 선택 시 다이얼로그 표시 (이미 참여 중이지 않은 경우만 호출됨)
  void _showGroupDialog(
    BuildContext context,
    Group group,
    GroupSearchNotifier notifier,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return GroupJoinDialog(
          group: group,
          onAction: (listAction) {
            // 다이얼로그 액션 처리
            // 먼저 타입을 확인한 후 명시적 처리
            if (listAction.runtimeType.toString().contains('OnCloseDialog')) {
              // 다이얼로그 닫기
              Navigator.of(context).pop();
              // 선택된 그룹 초기화
              notifier.onAction(const GroupSearchAction.resetSelectedGroup());
            } else if (listAction.runtimeType.toString().contains(
              'OnJoinGroup',
            )) {
              // 다이얼로그 닫기
              Navigator.of(context).pop();
              // 참여 중 메시지 표시
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '그룹 참여 중...',
                    style: TextStyle(color: AppColorStyles.white),
                  ),
                  duration: Duration(seconds: 1),
                ),
              );

              // listAction을 통해 groupId 가져오기 (reflection 또는 dynamic cast 방식)
              String groupId = group.id; // 필요한 경우 listAction에서 추출
              notifier.onAction(GroupSearchAction.onJoinGroup(groupId));
            }
          },
        );
      },
    );
  }
}
