// lib/auth/presentation/signup/signup_screen_root.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_action.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_notifier.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_screen.dart';
import 'package:devlink_mobile_app/core/result/result.dart';

class SignupScreenRoot extends ConsumerStatefulWidget {
  final String? agreedTermsId;

  const SignupScreenRoot({
    super.key,
    this.agreedTermsId,
  });

  @override
  ConsumerState<SignupScreenRoot> createState() => _SignupScreenRootState();
}

class _SignupScreenRootState extends ConsumerState<SignupScreenRoot> {
  @override
  void initState() {
    super.initState();

    // 약관 동의 ID가 있으면 설정
    if (widget.agreedTermsId != null) {
      // 다음 프레임에서 notifier 접근 (initState에서 ref.read 사용)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(signupNotifierProvider.notifier).setAgreedTermsId(widget.agreedTermsId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signupNotifierProvider);
    final notifier = ref.watch(signupNotifierProvider.notifier);

    // 회원가입 결과 상태 감지
    ref.listen(signupNotifierProvider.select((value) => value.signupResult), (previous, next) {
      if (previous?.isLoading == true && next?.hasValue == true) {
        // 회원가입 성공 시
        notifier.resetForm();

        // 성공 메시지를 SnackBar로 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('회원가입에 성공했습니다. 로그인해주세요.'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );

        // 로그인 페이지로 이동
        context.go('/');
      } else if (next?.hasError == true) {
        // 에러 처리
        final error = next!.error;
        String errorMessage;

        if (error is Failure) {
          errorMessage = error.message;
        } else if (error is Exception) {
          errorMessage = error.toString().replaceFirst('Exception: ', '');
        } else {
          errorMessage = '회원가입 실패: 알 수 없는 오류가 발생했습니다';
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
    });

    // 통합 오류 메시지 감지 - 약관 관련 오류는 제외
    ref.listen(signupNotifierProvider.select((value) => value.formErrorMessage), (previous, next) {
      // 폼 에러 메시지가 있고, 약관 관련 메시지가 아닌 경우에만 SnackBar 표시
      if (next != null && !next.contains('약관에 동의') && !next.contains('약관')) {
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
    });

    return SignupScreen(
      state: state,
      onAction: (action) {
        switch (action) {
          case NavigateToLogin():
            context.go('/');

          case NavigateToTerms():
            context.push('/terms');

          default:
          // 나머지 액션은 Notifier에서 처리
            notifier.onAction(action);
        }
      },
    );
  }
}