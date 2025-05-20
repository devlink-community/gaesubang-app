import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../auth/module/auth_di.dart';
import 'home_action.dart';
import 'home_notifier.dart';
import 'home_screen.dart';

class HomeScreenRoot extends ConsumerWidget {
  const HomeScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(homeNotifierProvider.notifier);
    final state = ref.watch(homeNotifierProvider);

    /// 더 간단한 방법으로 사용자 정보 가져오기
    final currentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);

    // 사용자 스킬 정보
    String? userSkills;

    // 비동기 호출로 사용자 정보 가져오기
    // 이 작업은 비동기로 처리할 수도 있고, FutureBuilder를 사용할 수도 있습니다.
    // 여기서는 간단하게 UseCase를 직접 호출합니다.
    ref.listen<AsyncValue<void>>(
      FutureProvider((ref) async {
        try {
          final result = await currentUserUseCase.execute();
          if (result is AsyncData) {
            final member = result.value;
            if (member != null) {
              userSkills = member.skills;
              debugPrint('HomeScreenRoot: 사용자 스킬 정보 - $userSkills');
            }
          }
        } catch (e) {
          debugPrint('HomeScreenRoot: 사용자 정보 가져오기 실패 - $e');
        }
      }),
      (_, __) {},
    );
    return HomeScreen(
      state: state,
      userSkills: userSkills,
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
