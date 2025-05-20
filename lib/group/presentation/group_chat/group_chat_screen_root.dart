
// lib/group/presentation/group_chat/group_chat_screen_root.dart

import 'package:devlink_mobile_app/group/presentation/group_chat/group_chat_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_chat/group_chat_notifier.dart';
import 'package:devlink_mobile_app/group/presentation/group_chat/group_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 그룹 채팅 화면의 Root 클래스
/// Notifier와 Screen 사이의 중간 계층으로, 상태 주입 및 화면 이동 담당
class GroupChatScreenRoot extends ConsumerStatefulWidget {
  final String groupId;

  const GroupChatScreenRoot({
    super.key, 
    required this.groupId
  });

  @override
  ConsumerState<GroupChatScreenRoot> createState() => _GroupChatScreenRootState();
}

class _GroupChatScreenRootState extends ConsumerState<GroupChatScreenRoot> {
  @override
  void initState() {
    super.initState();
    
    // 위젯 빌드 이후로 초기화 로직 지연
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 그룹 ID 설정 및 초기 메시지 로드
      ref.read(groupChatNotifierProvider.notifier).onAction(
        GroupChatAction.setGroupId(widget.groupId)
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // 상태와 Notifier 구독
    final state = ref.watch(groupChatNotifierProvider);
    final notifier = ref.read(groupChatNotifierProvider.notifier);

    return GroupChatScreen(
      state: state,
      onAction: (action) async {
        switch (action) {
          case SendMessage():
            // 메시지 전송 액션은 Notifier에 위임
            await notifier.onAction(action);
            break;
            
          case LoadMoreMessages():
            // 더 많은 메시지 로드 액션 위임
            await notifier.onAction(action);
            break;
            
          default:
            // 그 외 모든 액션 위임
            await notifier.onAction(action);
            break;
        }
      },
    );
  }
}