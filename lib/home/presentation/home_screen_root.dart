import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import 'home_action.dart';
import 'home_notifier.dart';
import 'home_screen.dart';

class HomeScreenRoot extends ConsumerWidget {
  const HomeScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(homeNotifierProvider.notifier);
    final state = ref.watch(homeNotifierProvider);

    // AuthState 가져오기
    final authStateAsync = ref.watch(authStateProvider);

    // 사용자 스킬 초기화
    String? userSkills;

    // AuthState에서 스킬 정보 추출 - 리플렉션 대신 패턴 매칭 사용
    if (authStateAsync case AsyncData(value: final authState)) {
      // 디버깅 로그 추가
      debugPrint('HomeScreenRoot - AuthState 타입: ${authState.runtimeType}');

      // authState를 문자열로 변환하여 skills 값 추출 시도
      final authStateStr = authState.toString();
      final skillsPattern = RegExp(r'skills: ([^,\)]+)');
      final match = skillsPattern.firstMatch(authStateStr);

      if (match != null && match.groupCount >= 1) {
        userSkills = match.group(1);
        // 스킬이 null 문자열이거나 비어있으면 null로 처리
        if (userSkills == 'null' || userSkills!.isEmpty) {
          userSkills = null;
        }
        debugPrint('HomeScreenRoot - 추출한 skills: $userSkills');
      }
    }

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
