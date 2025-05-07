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
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '안녕하세요. 저희는 소그룹을 만들어...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                '"${group.name}" 스터디에 참여하시겠습니까?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                '멤버 추가 인증이 필요할 수 있습니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          actions: [
            SizedBox(
              width: 140,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed:
                    () => notifier.onAction(
                      const GroupListAction.onCloseDialog(),
                    ),
                child: const Text('취소'),
              ),
            ),
            SizedBox(
              width: 140,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed:
                    () => notifier.onAction(
                      GroupListAction.onJoinGroup(group.id),
                    ),
                child: const Text('참여하기'),
              ),
            ),
          ],
        );
      },
    );
  }
}
