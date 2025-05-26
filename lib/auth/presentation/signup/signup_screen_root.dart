// lib/auth/presentation/signup/signup_screen_root.dart

import 'package:devlink_mobile_app/auth/presentation/signup/signup_action.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_notifier.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_screen.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/onboarding/presentation/onboarding_notifier.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SignupScreenRoot extends ConsumerStatefulWidget {
  const SignupScreenRoot({
    super.key,
  });

  @override
  ConsumerState<SignupScreenRoot> createState() => _SignupScreenRootState();
}

class _SignupScreenRootState extends ConsumerState<SignupScreenRoot> {
  @override
  void initState() {
    super.initState();
  }

  /// 🆕 개선된 온보딩 상태 리셋 메서드 (OnboardingNotifier의 새 메서드 사용)
  Future<void> _resetOnboardingForNewUser() async {
    try {
      AppLogger.info('회원가입 후 신규 사용자 온보딩 초기화 시작', tag: 'SignupScreenRoot');
      
      // OnboardingNotifier의 새로운 resetOnboardingForNewUser 메서드 호출
      final onboardingNotifier = ref.read(onboardingNotifierProvider.notifier);
      await onboardingNotifier.resetOnboardingForNewUser();
      
      AppLogger.info('신규 사용자 온보딩 초기화 완료', tag: 'SignupScreenRoot');
    } catch (e) {
      AppLogger.error(
        '신규 사용자 온보딩 초기화 실패',
        tag: 'SignupScreenRoot',
        error: e,
      );
      
      // 실패해도 계속 진행 (온보딩 화면에서 다시 시도 가능)
      AppLogger.warning('온보딩 초기화 실패했지만 온보딩 화면으로 이동 계속 진행');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signupNotifierProvider);
    final notifier = ref.watch(signupNotifierProvider.notifier);

    // 🔥 회원가입 결과 상태 감지 (성공/실패 모두 여기서 처리)
    ref.listen(signupNotifierProvider.select((value) => value.signupResult), (
      previous,
      next,
    ) {
      // 로딩 중이거나 결과가 없으면 무시
      if (next == null || next.isLoading) return;

      if (next.hasValue) {
        // ✅ 회원가입 + 자동 로그인 성공 처리
        notifier.resetForm();

        // 성공 메시지를 SnackBar로 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('회원가입이 완료되었습니다! 권한 설정을 진행해주세요.'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: '확인',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );

        // 🔥 개선된 온보딩 상태 리셋 후 온보딩 화면으로 이동
        _resetOnboardingForNewUser().then((_) {
          if (mounted) {
            AppLogger.info('회원가입 완료 후 온보딩 화면으로 이동', tag: 'SignupScreenRoot');
            
            // 상태 업데이트 완료 후 온보딩 화면으로 이동
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                // pushReplacement를 사용하여 뒤로가기 시 회원가입 화면으로 돌아가지 않도록 함
                context.pushReplacement('/onboarding');
              }
            });
          }
        }).catchError((error) {
          // 온보딩 초기화 실패해도 온보딩 화면으로 이동
          AppLogger.error(
            '온보딩 초기화 실패했지만 온보딩 화면으로 이동 계속',
            tag: 'SignupScreenRoot',
            error: error,
          );
          
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.pushReplacement('/onboarding');
              }
            });
          }
        });
      } else if (next.hasError) {
        // ❌ 회원가입 실패 처리
        final error = next.error;
        String errorMessage;

        if (error is Failure) {
          errorMessage = error.message;
        } else if (error is Exception) {
          errorMessage = error.toString().replaceFirst('Exception: ', '');
        } else {
          errorMessage = '회원가입 실패: 알 수 없는 오류가 발생했습니다';
        }

        AppLogger.error(
          '회원가입 실패',
          tag: 'SignupScreenRoot',
          error: error,
        );

        // 에러 메시지를 SnackBar로 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: '확인',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    });

    // 🔥 폼 검증 에러만 처리 (회원가입 관련 에러는 위에서 처리하므로 제외)
    ref.listen(
      signupNotifierProvider.select((value) => value.formErrorMessage),
      (previous, next) {
        // 폼 에러 메시지가 있고, 회원가입 진행 중이 아닌 경우에만 SnackBar 표시
        if (next != null && !_isSignupInProgress(state)) {
          // 🔥 회원가입 관련 에러는 signupResult 리스너에서 처리하므로 여기서는 제외
          if (_isSignupRelatedError(next)) {
            return; // 회원가입 관련 에러는 처리하지 않음
          }

          // 폼 검증 에러만 SnackBar로 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next),
              backgroundColor: Colors.orange.shade800,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: '확인',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      },
    );

    return SignupScreen(
      state: state,
      onAction: (action) async {
        switch (action) {
          case NavigateToLogin():
            context.go('/login');

          case NavigateToTerms():
            // 약관 화면으로 이동하고 결과 받기 (true = 약관 동의 완료)
            final result = await context.push<bool>('/terms');

            // 약관 동의 완료 상태를 업데이트
            if (result == true) {
              AppLogger.authInfo('약관 동의 완료 - 체크박스 상태 업데이트');
              notifier.updateTermsAgreement(isAgreed: true);
            } else if (result == false) {
              // 약관에 동의하지 않은 경우
              AppLogger.authInfo('약관 미동의 - 체크박스 해제');
              notifier.updateTermsAgreement(isAgreed: false);
            }
          // result가 null인 경우(그냥 뒤로가기)는 상태 변경 없음
          default:
            // 나머지 액션은 Notifier에서 처리
            notifier.onAction(action);
        }
      },
    );
  }

  /// 회원가입이 진행 중인지 확인
  bool _isSignupInProgress(state) {
    return state.signupResult?.isLoading == true;
  }

  /// 회원가입 관련 에러인지 확인
  bool _isSignupRelatedError(String errorMessage) {
    const signupRelatedKeywords = [
      '이미 사용 중인 이메일',
      '이미 사용 중인 닉네임',
      '계정 생성',
      '회원가입',
      '약관',
      '네트워크 연결',
      '너무 많은 요청',
      '비밀번호가 너무 약',
      '잘못된 이메일',
      '사용자 정보 저장',
    ];

    return signupRelatedKeywords.any(
      (keyword) => errorMessage.contains(keyword),
    );
  }
}