// lib/auth/presentation/forget_password/forget_password_screen_root.dart
import 'package:devlink_mobile_app/auth/presentation/forget_password/forget_password_action.dart';
import 'package:devlink_mobile_app/auth/presentation/forget_password/forget_password_notifier.dart';
import 'package:devlink_mobile_app/auth/presentation/forget_password/forget_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ForgetPasswordScreenRoot extends ConsumerWidget {
  const ForgetPasswordScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(forgetPasswordNotifierProvider);
    final notifier = ref.watch(forgetPasswordNotifierProvider.notifier);

    return ForgetPasswordScreen(
      state: state,
      onAction: (action) {
        switch (action) {
          case NavigateToLogin():
            context.go('/'); // 로그인 화면으로 이동
          default:
          // 나머지 액션은 Notifier에서 처리
            notifier.onAction(action);
        }
      },
    );
  }
}