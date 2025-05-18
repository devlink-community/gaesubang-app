import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
  void initState() {
    super.initState();
    // 화면이 처음 로드될 때 딱 한 번만 호출
    _maybeRefreshData();
  }

  // 필요한 경우에만 데이터 새로고침
  void _maybeRefreshData() {
    // Provider 상태를 먼저 확인
    final introState = ref.read(introNotifierProvider);

    // 로딩 중이 아니고 에러가 있거나 데이터가 없는 경우만 새로고침
    if (!introState.isLoading &&
        (introState.hasError || !introState.hasValue)) {
      debugPrint('인트로 화면 데이터 새로고침 필요');
      _refreshData();
    } else {
      debugPrint('인트로 화면 데이터 이미 로드됨');
    }
  }

  // 인트로 화면 데이터 새로고침
  void _refreshData() {
    debugPrint('인트로 화면 데이터 새로고침 실행');
    // 명시적으로 새로고침 액션 호출
    ref.read(introNotifierProvider.notifier).onAction(const RefreshIntro());
  }

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
                  debugPrint('설정 버튼 클릭됨 - 설정 화면으로 이동 시도');
                  context.push('/settings');
                  break;
                case RefreshIntro():
                  debugPrint('새로고침 버튼 클릭됨');
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
