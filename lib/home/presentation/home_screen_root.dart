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

    // AsyncValue<AuthState> 가져오기
    final authStateAsync = ref.watch(authStateProvider);

    // 사용자 스킬 초기화
    String? userSkills;

    // AsyncValue 패턴 매칭으로 처리
    if (authStateAsync case AsyncData(:final value)) {
      // value는 이제 AuthState 타입
      if (value.runtimeType.toString() == 'Authenticated') {
        // 사용자 정보 추출 (리플렉션 사용)
        final authStateStr = value.toString();

        // 로그에서 skills 부분 추출
        final skillsStart = authStateStr.indexOf('skills: ');
        if (skillsStart != -1) {
          final afterSkills = authStateStr.substring(
            skillsStart + 8,
          ); // 'skills: ' 다음부터

          // 쉼표 또는 닫는 괄호 찾기
          final commaIndex = afterSkills.indexOf(',');
          final bracketIndex = afterSkills.indexOf(')');

          final endIndex =
              commaIndex != -1 && commaIndex < bracketIndex
                  ? commaIndex
                  : bracketIndex;

          if (endIndex != -1) {
            userSkills = afterSkills.substring(0, endIndex);
            debugPrint('HomeScreenRoot - 사용자 스킬 추출: $userSkills');
          }
        }
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
      userSkills: userSkills,
    );
  }
}
