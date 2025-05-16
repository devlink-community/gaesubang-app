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

    // 로그인 결과 상태 감지
    ref.listen(loginNotifierProvider.select((value) => value.loginUserResult), (previous, next) {
      // 로그인 성공 시 홈 화면으로 이동
      if (next?.hasValue == true) {
        context.go('/home');
      }

      // 로그인 실패 시 Snackbar로 에러 메시지 표시
      if (next?.hasError == true) {
        final error = next!.error;
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

    // 별도로 에러 메시지 상태 감지
    ref.listen(loginNotifierProvider.select((value) => value.loginErrorMessage), (previous, next) {
      if (next != null) {
        // SnackBar로 에러 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next),
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