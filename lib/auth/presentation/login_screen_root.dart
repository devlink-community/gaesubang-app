import 'package:devlink_mobile_app/auth/presentation/login_action.dart';
import 'package:devlink_mobile_app/auth/presentation/login_screen.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'login_notifier.dart';

class LoginScreenRoot extends ConsumerWidget {
  const LoginScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginNotifierProvider);
    final notifier = ref.watch(loginNotifierProvider.notifier);

    // 로그인 성공 시 홈으로 이동
    final loginResult = state.loginUserResult;
    if (loginResult?.hasValue == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/home');
        notifier.logout();
      });
    }

    // 로딩 처리
    if (state.loginUserResult?.isLoading == true) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 에러 처리
    if (state.loginUserResult?.hasError == true) {
      final error = state.loginUserResult!.error;
      if (error is Failure) {
        return Scaffold(
          body: Center(
            child: Text(
              '로그인 실패: ${error.message}',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        );
      } else {
        return const Scaffold(
          body: Center(
            child: Text('알 수 없는 오류', style: TextStyle(color: Colors.red)),
          ),
        );
      }
    }

    // 정상 화면
    return LoginScreen(
      state: state,
      onAction: (action) async {
        switch (action) {
          case NavigateToForgetPassword():
            context.push('/forget-password');
          case NavigateToSignUp():
            context.push('/sign-up');
          case LoginPressed():
            await notifier.onAction(action);
        }
      },
    );
  }
}
