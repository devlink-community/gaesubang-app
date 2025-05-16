// lib/auth/presentation/forgot_password/forgot_password_screen_root.dart

import 'package:devlink_mobile_app/auth/presentation/forgot_password/forgot_password_action.dart';
import 'package:devlink_mobile_app/auth/presentation/forgot_password/forgot_password_notifier.dart';
import 'package:devlink_mobile_app/auth/presentation/forgot_password/forgot_password_screen.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ForgotPasswordScreenRoot extends ConsumerWidget {
  const ForgotPasswordScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(forgotPasswordNotifierProvider);
    final notifier = ref.watch(forgotPasswordNotifierProvider.notifier);

    // 비밀번호 재설정 이메일 전송 결과 감지
    ref.listen(
      forgotPasswordNotifierProvider.select((value) => value.resetPasswordResult),
          (previous, next) {
        if (previous?.isLoading == true && next?.hasValue == true) {
          // 성공 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage ?? '이메일이 발송되었습니다.'),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (next?.hasError == true) {
          // 에러 메시지 처리
          final error = next!.error;
          String errorMessage;

          if (error is Failure) {
            errorMessage = error.message;
          } else if (error is Exception) {
            errorMessage = error.toString().replaceFirst('Exception: ', '');
          } else {
            errorMessage = '이메일 발송 실패: 알 수 없는 오류가 발생했습니다';
          }

          // 에러 메시지를 SnackBar로 표시
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
      },
    );

    // 통합 오류 메시지 감지
    ref.listen(
      forgotPasswordNotifierProvider.select((value) => value.formErrorMessage),
          (previous, next) {
        if (next != null) {
          // 폼 에러 메시지를 SnackBar로 표시
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
      },
    );

    return ForgotPasswordScreen(
      state: state,
      onAction: (action) {
        switch (action) {
          case NavigateToLoginAction():
            context.go('/'); // 로그인 화면으로 이동
          default:
            notifier.onAction(action);
        }
      },
    );
  }
}