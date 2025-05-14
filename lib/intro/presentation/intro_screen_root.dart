import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/component/navigation_bar.dart';
import 'intro_action.dart';
import 'intro_notifier.dart';
import 'intro_screen.dart';

class IntroScreenRoot extends ConsumerStatefulWidget {
  const IntroScreenRoot({super.key});

  @override
  ConsumerState<IntroScreenRoot> createState() => _IntroScreenRootState();
}

class _IntroScreenRootState extends ConsumerState<IntroScreenRoot> {
  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(introNotifierProvider.notifier);
    final state = ref.watch(introNotifierProvider);

    return state.when(
      data: (data) {
        return Scaffold(
          body: IntroScreen(
            state: data,
            onAction: (action) async {
              switch (action) {
                case OpenSettings():
                  print('설정 버튼 클릭됨 - 설정 화면으로 이동 시도');
                  context.go('/settings');
                  break;
                case RefreshIntro():
                  print('새로고침 버튼 클릭됨');
                  await notifier.onAction(action);
                  break;
              }
            },
          ),
        );
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (error, stackTrace) =>
              Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}
