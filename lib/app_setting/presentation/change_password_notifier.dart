import 'package:devlink_mobile_app/auth/domain/usecase/reset_password_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/app_setting/presentation/change_password_action.dart';
import 'package:devlink_mobile_app/app_setting/presentation/change_password_state.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/auth_validator.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'change_password_notifier.g.dart';

@riverpod
class ChangePasswordNotifier extends _$ChangePasswordNotifier {
  late final ResetPasswordUseCase _resetPasswordUseCase;

  @override
  ChangePasswordState build() {
    _resetPasswordUseCase = ref.watch(resetPasswordUseCaseProvider);
    return const ChangePasswordState();
  }

  Future<void> onAction(ChangePasswordAction action) async {
    switch (action) {
      case EmailChanged(:final email):
        state = state.copyWith(
          email: email,
          emailError: null,
          formErrorMessage: null,
        );

      case EmailFocusChanged(:final hasFocus):
        if (!hasFocus && state.email.isNotEmpty) {
          final error = AuthValidator.validateEmail(state.email);
          state = state.copyWith(emailError: error);
        }

      case SendResetEmail():
        await _performResetPassword();

      case NavigateBack():
        // Root에서 처리됨
        break;
    }
  }

  Future<void> _performResetPassword() async {
    // 이메일 유효성 검증
    final emailError = AuthValidator.validateEmail(state.email);
    state = state.copyWith(emailError: emailError);

    if (emailError != null) {
      return;
    }

    // 비밀번호 재설정 이메일 전송
    state = state.copyWith(
      resetPasswordResult: const AsyncLoading(),
      successMessage: null,
      formErrorMessage: null,
    );

    final result = await _resetPasswordUseCase.execute(state.email);

    if (result.hasError) {
      final error = result.error;
      String errorMessage = AuthErrorMessages.passwordResetFailed;

      if (error is Failure) {
        switch (error.type) {
          case FailureType.validation:
            errorMessage = error.message;
            break;
          case FailureType.network:
            errorMessage = AuthErrorMessages.networkError;
            break;
          case FailureType.timeout:
            errorMessage = AuthErrorMessages.timeoutError;
            break;
          default:
            errorMessage = error.message;
        }
      }

      debugPrint('비밀번호 재설정 에러: $error');

      state = state.copyWith(
        resetPasswordResult: result,
        formErrorMessage: errorMessage,
      );
    } else {
      state = state.copyWith(
        resetPasswordResult: result,
        successMessage: '비밀번호 재설정 이메일이 발송되었습니다.',
        formErrorMessage: null,
      );
    }
  }

  void resetForm() {
    state = const ChangePasswordState();
  }
}
