import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'intro_action.dart';
import 'intro_notifier.dart';
import 'intro_screen.dart';

class IntroScreenRoot extends ConsumerWidget {
  const IntroScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(introNotifierProvider.notifier);
    final state = ref.watch(introNotifierProvider);

    return state.when(
      data:
          (data) => IntroScreen(
            state: data,
            onAction: (action) async {
              // async 키워드 추가
              switch (action) {
                case OpenSettings():
                  // 설정 화면으로 이동
                  print('설정 버튼 클릭됨 - 설정 화면으로 이동 시도');
                  context.go('/settings');
                  break; // break 문 추가
                case RefreshIntro():
                  print('새로고침 버튼 클릭됨');
                  await notifier.onAction(action); // await 키워드 추가
                  break; // break 문 추가
              }
            },
          ),
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (error, stackTrace) =>
              Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}
