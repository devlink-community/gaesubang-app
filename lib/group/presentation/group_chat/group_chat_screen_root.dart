// lib/group/presentation/group_chat/group_chat_screen_root.dart
import 'package:devlink_mobile_app/group/presentation/group_chat/group_chat_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_chat/group_chat_notifier.dart';
import 'package:devlink_mobile_app/group/presentation/group_chat/group_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GroupChatScreenRoot extends ConsumerStatefulWidget {
  const GroupChatScreenRoot({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupChatScreenRoot> createState() => _GroupChatScreenRootState();
}

class _GroupChatScreenRootState extends ConsumerState<GroupChatScreenRoot> with WidgetsBindingObserver {
  // 화면 상태 관리
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // 앱 상태 변화 감지를 위한 관찰자 등록
    WidgetsBinding.instance.addObserver(this);

    // 화면 초기화를 위젯 빌드 이후로 지연
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  // 화면 초기화 (최초 진입 시에만 호출)
  Future<void> _initializeScreen() async {
    if (_isInitialized) return;

    print('🚀 그룹 채팅 화면 초기화 시작 - groupId: ${widget.groupId}');

    if (mounted) {
      final notifier = ref.read(groupChatNotifierProvider.notifier);
      await notifier.onAction(GroupChatAction.setGroupId(widget.groupId));
    }

    _isInitialized = true;
    print('✅ 그룹 채팅 화면 초기화 완료');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // 앱이 포그라운드로 돌아왔을 때
        if (_isInitialized && mounted) {
          // 메시지 읽음 상태 업데이트
          final notifier = ref.read(groupChatNotifierProvider.notifier);
          notifier.onAction(const GroupChatAction.markAsRead());
        }
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    // 관찰자 해제
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 상태 구독
    final state = ref.watch(groupChatNotifierProvider);
    final notifier = ref.read(groupChatNotifierProvider.notifier);

    return GroupChatScreen(
      state: state,
      onAction: notifier.onAction,
    );
  }
}