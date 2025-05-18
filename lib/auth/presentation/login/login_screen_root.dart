// lib/auth/presentation/login/login_screen_root.dart
import 'package:devlink_mobile_app/auth/presentation/login/login_action.dart';
import 'package:devlink_mobile_app/auth/presentation/login/login_screen.dart';
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

    // 로그인 결과 상태와 에러 메시지를 함께 감지 (두 상태 모두 변경됨)
    ref.listen(loginNotifierProvider, (previous, current) {
      // 로그인 성공 시 홈 화면으로 이동
      if (current.loginUserResult?.hasValue == true) {
        context.go('/home');
      }

      // 오류 메시지가 있는 경우에만 SnackBar 표시
      final errorMessage = current.loginErrorMessage;
      final hasLoginError = current.loginUserResult?.hasError == true;

      // 에러 메시지가 있거나 로그인 결과에 오류가 있는 경우 (둘 중 하나만 처리)
      if (errorMessage != null) {
        // SnackBar로 에러 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (hasLoginError && previous?.loginUserResult != current.loginUserResult) {
        // loginUserResult에 오류가 있고, 이전 상태와 다를 경우에만 처리
        final error = current.loginUserResult!.error;
        String errorMessage;

        if (error is Failure) {
          errorMessage = error.message;
        } else if (error is Exception) {
          errorMessage = error.toString().replaceFirst('Exception: ', '');
        } else {
          errorMessage = '로그인 중 오류가 발생했습니다';
        }

        // SnackBar로 에러 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    return LoginScreen(
      state: state,
      onAction: (action) async {
        switch (action) {
          case NavigateToForgetPassword():
            context.push('/forget-password');
            break;
          case NavigateToSignUp():
            context.push('/sign-up');
            break;
          default:
            await notifier.onAction(action);
            break;
        }
      },
    );
  }
}