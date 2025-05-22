import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/result/result.dart';
import 'change_password.dart';
import 'change_password_action.dart';
import 'change_password_notifier.dart';

class ChangePasswordScreenRoot extends ConsumerWidget {
  const ChangePasswordScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(changePasswordNotifierProvider);
    final notifier = ref.read(changePasswordNotifierProvider.notifier);

    // 비밀번호 재설정 이메일 전송 결과 감지
    ref.listen(
      changePasswordNotifierProvider.select(
        (value) => value.resetPasswordResult,
      ),
      (previous, next) {
        if (previous?.isLoading == true && next?.hasValue == true) {
          // 성공 메시지 표시
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage ?? '이메일이 발송되었습니다.'),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 3),
              ),
            );
          }
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

          if (context.mounted) {
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
        }
      },
    );

    // 통합 오류 메시지 감지
    ref.listen(
      changePasswordNotifierProvider.select((value) => value.formErrorMessage),
      (previous, next) {
        if (next != null &&
            !next.contains('유효한 이메일') &&
            !next.contains('이메일을 입력')) {
          if (context.mounted) {
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
        }
      },
    );

    return ChangePasswordScreen(
      state: state,
      onAction: (action) {
        switch (action) {
          case NavigateBack():
            // Navigator key 충돌 방지를 위해 안전한 pop 처리
            if (context.mounted && context.canPop()) {
              context.pop();
            }
          default:
            notifier.onAction(action);
        }
      },
    );
  }
}
