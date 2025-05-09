// lib/auth/presentation/forget_password/forget_password_notifier.dart
import 'package:devlink_mobile_app/auth/domain/usecase/reset_password_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/validate_email_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/auth/presentation/forget_password/forget_password_action.dart';
import 'package:devlink_mobile_app/auth/presentation/forget_password/forget_password_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'forget_password_notifier.g.dart';

@riverpod
class ForgetPasswordNotifier extends _$ForgetPasswordNotifier {
  late final ResetPasswordUseCase _resetPasswordUseCase;
  late final ValidateEmailUseCase _validateEmailUseCase;

  @override
  ForgetPasswordState build() {
    _resetPasswordUseCase = ref.watch(resetPasswordUseCaseProvider);
    _validateEmailUseCase = ref.watch(validateEmailUseCaseProvider);
    return const ForgetPasswordState();
  }

  Future<void> onAction(ForgetPasswordAction action) async {
    switch (action) {
    // 이메일 변경 처리
      case EmailChanged(:final email):
        state = state.copyWith(
          email: email,
          emailError: null, // 사용자가 입력 중이면 에러 메시지 제거
        );

    // 이메일 포커스 변경 처리 (유효성 검증 트리거)
      case EmailFocusChanged(:final hasFocus):
        if (!hasFocus && state.email.isNotEmpty) {
          // 포커스를 잃을 때만 유효성 검증
          final error = await _validateEmailUseCase.execute(state.email);
          state = state.copyWith(emailError: error);
        }

    // 폼 제출 처리
      case Submit():
        await _performResetPassword();

    // 로그인 화면으로 이동(Root에서 처리)
      case NavigateToLogin():
        break;
    }
  }

  // 비밀번호 재설정 수행
  Future<void> _performResetPassword() async {
    // 1. 이메일 유효성 검증
    final emailError = await _validateEmailUseCase.execute(state.email);
    state = state.copyWith(emailError: emailError);

    // 유효성 검증 오류가 있으면 처리 중단
    if (emailError != null) return;

    // 2. 비밀번호 재설정 요청
    state = state.copyWith(
      resetPasswordResult: const AsyncLoading(),
      successMessage: null,
    );

    final result = await _resetPasswordUseCase.execute(state.email);

    // 3. 결과 처리
    if (result case AsyncData()) {
      state = state.copyWith(
        resetPasswordResult: result,
        successMessage: '비밀번호 재설정 이메일이 발송되었습니다. 이메일을 확인해주세요.',
      );
    } else {
      state = state.copyWith(
        resetPasswordResult: result,
        successMessage: null,
      );
    }
  }

  // 폼 리셋
  void resetForm() {
    state = const ForgetPasswordState();
  }
}