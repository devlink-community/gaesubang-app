// lib/auth/presentation/signup/signup_screen_root.dart
import 'package:devlink_mobile_app/auth/presentation/signup/signup_action.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_notifier.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SignupScreenRoot extends ConsumerWidget {
  const SignupScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signupNotifierProvider);
    final notifier = ref.watch(signupNotifierProvider.notifier);

    // 회원가입 성공 감지 및 이동
    ref.listen(signupNotifierProvider.select((value) => value.signupResult), (previous, next) {
      if (previous?.isLoading == true && next?.hasValue == true) {
        // 회원가입 성공 후 폼 리셋
        notifier.resetForm();

        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입에 성공했습니다. 로그인해주세요.')),
        );

        // 로그인 페이지로 이동
        context.go('/');
      } else if (next?.hasError == true) {
        // 에러 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 실패: ${next!.error}')),
        );
      }
    });

    return SignupScreen(
      state: state,
      onAction: (action) {
        switch (action) {
          case NavigateToLogin():
            context.go('/');

          case NavigateToTerms():
          // 약관 페이지로 이동 (현재 구현 예정 페이지가 없으므로 대화상자로 대체)
            _showTermsDialog(context);

          default:
          // 나머지 액션은 Notifier에서 처리
            notifier.onAction(action);
        }
      },
    );
  }

  // 약관 대화상자 표시 (임시)
  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이용약관'),
        content: const SingleChildScrollView(
          child: Text(
            '이용약관 내용이 여기에 표시됩니다. 실제 애플리케이션에서는 '
                '상세한 이용약관 텍스트가 포함되어야 합니다.\n\n'
                '서비스 이용에 관한 약관, 개인정보 처리방침 등이 여기에 기술됩니다.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}