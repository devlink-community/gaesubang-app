// lib/auth/presentation/forgot_password/forgot_password_notifier.dart
import 'package:devlink_mobile_app/auth/domain/usecase/reset_password_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/auth/presentation/forgot_password/forgot_password_action.dart';
import 'package:devlink_mobile_app/auth/presentation/forgot_password/forgot_password_state.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/auth_validator.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'forgot_password_notifier.g.dart';

@riverpod
class ForgotPasswordNotifier extends _$ForgotPasswordNotifier {
  late final ResetPasswordUseCase _resetPasswordUseCase;

  @override
  ForgotPasswordState build() {
    _resetPasswordUseCase = ref.watch(resetPasswordUseCaseProvider);
    return const ForgotPasswordState();
  }

  Future<void> onAction(ForgotPasswordAction action) async {
    switch (action) {
      case EmailChangedAction(:final email):
        state = state.copyWith(
          email: email,
          emailError: null,
          formErrorMessage: null, // 입력 변경 시 오류 메시지 초기화
        );

      case EmailFocusChangedAction(:final hasFocus):
        if (!hasFocus && state.email.isNotEmpty) {
          final error = AuthValidator.validateEmail(state.email);
          state = state.copyWith(
            emailError: error,
            // formErrorMessage는 설정하지 않음 (중복 메시지 방지)
          );
        }

      case SendResetEmailAction():
        await _performResetPassword();

      case NavigateToLoginAction():
        // Root에서 처리됨
        break;
    }
  }

  Future<void> _performResetPassword() async {
    // 이메일 유효성 검증
    final emailError = AuthValidator.validateEmail(state.email);
    state = state.copyWith(emailError: emailError);

    // 이메일이 유효하지 않으면 중단
    if (emailError != null) {
      // formErrorMessage는 설정하지 않음 (중복 메시지 방지)
      return;
    }

    // 비밀번호 재설정 이메일 전송
    state = state.copyWith(
      resetPasswordResult: const AsyncLoading(),
      successMessage: null, // 전송 시작할 때 성공 메시지 초기화
      formErrorMessage: null, // 오류 메시지도 초기화
    );

    // 이메일 주소는 그대로 전달하고 소문자 변환은 DataSource에서 처리
    final result = await _resetPasswordUseCase.execute(state.email);

    // 결과 처리
    if (result.hasError) {
      final error = result.error;
      String errorMessage = AuthErrorMessages.passwordResetFailed;

      // 에러 타입에 따른 사용자 친화적 메시지 처리
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

      // 디버깅 정보 로깅
      debugPrint('비밀번호 재설정 에러: $error');

      // 오류 상태 업데이트
      state = state.copyWith(
        resetPasswordResult: result,
        formErrorMessage: errorMessage, // 통합 오류 메시지 설정 (SnackBar 표시용)
      );
    } else {
      // 성공 시 메시지 설정
      state = state.copyWith(
        resetPasswordResult: result,
        successMessage: AuthErrorMessages.passwordResetSuccess,
        formErrorMessage: null,
      );
    }
  }

  void resetForm() {
    state = const ForgotPasswordState();
  }
}
