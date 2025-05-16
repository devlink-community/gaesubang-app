import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'home_action.dart';
import 'home_notifier.dart';
import 'home_screen.dart';

class HomeScreenRoot extends ConsumerWidget {
  const HomeScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(homeNotifierProvider.notifier);
    final state = ref.watch(homeNotifierProvider);

    return HomeScreen(
      state: state,
      onAction: (action) async {
        switch (action) {
          case RefreshHome():
            await notifier.onAction(action);
            break;

          case OnTapNotice(:final noticeId):
            // 임시 처리: 토스트 메시지 표시
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('공지사항 $noticeId 클릭')));
            break;

          case OnTapGroup(:final groupId):
            // 그룹 상세 페이지로 이동
            context.push('/group/$groupId');
            break;

          case OnTapPopularPost(:final postId):
            // 게시글 상세 페이지로 이동
            context.push('/community/$postId');
            break;

          case OnTapSettings():
            // 설정 페이지로 이동
            context.push('/settings');
            break;

          case OnTapNotification():
            // 알림 페이지로 이동
            context.push('/notifications');
            break;
        }
      },
    );
  }
}
