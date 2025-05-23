// lib/auth/presentation/forgot_password/forgot_password_notifier.dart
import 'package:devlink_mobile_app/auth/domain/usecase/reset_password_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/auth/presentation/forgot_password/forgot_password_action.dart';
import 'package:devlink_mobile_app/auth/presentation/forgot_password/forgot_password_state.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/auth_validator.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'forgot_password_notifier.g.dart';

@riverpod
class ForgotPasswordNotifier extends _$ForgotPasswordNotifier {
  late final ResetPasswordUseCase _resetPasswordUseCase;

  @override
  ForgotPasswordState build() {
    AppLogger.authInfo('ForgotPasswordNotifier 초기화 시작');

    _resetPasswordUseCase = ref.watch(resetPasswordUseCaseProvider);

    AppLogger.authInfo('ForgotPasswordNotifier 초기화 완료');
    return const ForgotPasswordState();
  }

  Future<void> onAction(ForgotPasswordAction action) async {
    AppLogger.debug('비밀번호 재설정 액션 처리: ${action.runtimeType}');

    switch (action) {
      case EmailChangedAction(:final email):
        AppLogger.debug('이메일 입력 변경: ${email.length}자');
        state = state.copyWith(
          email: email,
          emailError: null,
          formErrorMessage: null, // 입력 변경 시 오류 메시지 초기화
        );

      case EmailFocusChangedAction(:final hasFocus):
        if (!hasFocus && state.email.isNotEmpty) {
          AppLogger.debug('이메일 필드 포커스 아웃 - 유효성 검증 시작');
          final error = AuthValidator.validateEmail(state.email);

          if (error != null) {
            AppLogger.warning('이메일 유효성 검증 실패', error: error);
          } else {
            AppLogger.debug('이메일 유효성 검증 통과');
          }

          state = state.copyWith(
            emailError: error,
            // formErrorMessage는 설정하지 않음 (중복 메시지 방지)
          );
        }

      case SendResetEmailAction():
        AppLogger.logBanner('비밀번호 재설정 이메일 전송 시작');
        await _performResetPassword();

      case NavigateToLoginAction():
        AppLogger.navigation('로그인 화면 이동 요청 (Root에서 처리)');
        // Root에서 처리됨
        break;
    }
  }

  Future<void> _performResetPassword() async {
    final startTime = DateTime.now();
    AppLogger.logStep(1, 4, '비밀번호 재설정 프로세스 시작');

    AppLogger.logState('비밀번호 재설정 요청 정보', {
      'email': state.email,
      'email_length': state.email.length,
    });

    AppLogger.logStep(2, 4, '이메일 유효성 검증');
    // 이메일 유효성 검증
    final emailError = AuthValidator.validateEmail(state.email);
    state = state.copyWith(emailError: emailError);

    // 이메일이 유효하지 않으면 중단
    if (emailError != null) {
      AppLogger.warning('이메일 유효성 검증 실패 - 재설정 중단', error: emailError);
      // formErrorMessage는 설정하지 않음 (중복 메시지 방지)
      return;
    }

    AppLogger.logStep(3, 4, '비밀번호 재설정 이메일 전송 API 호출');
    // 비밀번호 재설정 이메일 전송
    state = state.copyWith(
      resetPasswordResult: const AsyncLoading(),
      successMessage: null, // 전송 시작할 때 성공 메시지 초기화
      formErrorMessage: null, // 오류 메시지도 초기화
    );

    // 이메일 주소는 그대로 전달하고 소문자 변환은 DataSource에서 처리
    final result = await _resetPasswordUseCase.execute(state.email);

    final duration = DateTime.now().difference(startTime);
    AppLogger.logPerformance('비밀번호 재설정 프로세스', duration);

    AppLogger.logStep(4, 4, '비밀번호 재설정 API 응답 처리');
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

      AppLogger.error('비밀번호 재설정 실패', error: error);
      AppLogger.logState('비밀번호 재설정 실패 상세', {
        'email': state.email,
        'error_type': error.runtimeType.toString(),
        'error_message': errorMessage,
        'failure_type': error is Failure ? error.type.toString() : 'unknown',
        'duration_ms': duration.inMilliseconds,
      });

      // 오류 상태 업데이트
      state = state.copyWith(
        resetPasswordResult: result,
        formErrorMessage: errorMessage, // 통합 오류 메시지 설정 (SnackBar 표시용)
      );
    } else {
      // 성공 시 메시지 설정
      AppLogger.logBox(
        '비밀번호 재설정 이메일 전송 성공',
        '이메일: ${state.email}\n소요시간: ${duration.inMilliseconds}ms',
      );

      AppLogger.authInfo('비밀번호 재설정 이메일 전송 완료');
      AppLogger.logState('비밀번호 재설정 성공 정보', {
        'email': state.email,
        'success': true,
        'duration_ms': duration.inMilliseconds,
      });

      state = state.copyWith(
        resetPasswordResult: result,
        successMessage: AuthErrorMessages.passwordResetSuccess,
        formErrorMessage: null,
      );
    }
  }

  void resetForm() {
    AppLogger.debug('비밀번호 재설정 폼 리셋');
    state = const ForgotPasswordState();
  }
}
