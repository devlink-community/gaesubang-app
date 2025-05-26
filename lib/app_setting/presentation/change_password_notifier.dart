import 'package:devlink_mobile_app/app_setting/presentation/change_password_action.dart';
import 'package:devlink_mobile_app/app_setting/presentation/change_password_state.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/core/reset_password_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/auth_validator.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/privacy_mask_util.dart';
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'change_password_notifier.g.dart';

@riverpod
class ChangePasswordNotifier extends _$ChangePasswordNotifier {
  late final ResetPasswordUseCase _resetPasswordUseCase;

  @override
  ChangePasswordState build() {
    _resetPasswordUseCase = ref.watch(resetPasswordUseCaseProvider);
    AppLogger.info(
      'ChangePasswordNotifier 초기화 완료',
      tag: 'ChangePasswordNotifier',
    );
    return const ChangePasswordState();
  }

  Future<void> onAction(ChangePasswordAction action) async {
    AppLogger.debug(
      'ChangePasswordAction 수신: ${action.runtimeType}',
      tag: 'ChangePasswordNotifier',
    );

    switch (action) {
      case EmailChanged(:final email):
        AppLogger.debug(
          '이메일 변경: ${PrivacyMaskUtil.maskEmail(email)}',
          tag: 'ChangePasswordForm',
        );
        state = state.copyWith(
          email: email,
          emailError: null,
          formErrorMessage: null,
        );

      case EmailFocusChanged(:final hasFocus):
        AppLogger.debug('이메일 포커스 변경: $hasFocus', tag: 'ChangePasswordForm');
        if (!hasFocus && state.email.isNotEmpty) {
          final error = AuthValidator.validateEmail(state.email);
          if (error != null) {
            AppLogger.warning(
              '이메일 유효성 검사 실패: $error',
              tag: 'ChangePasswordValidation',
            );
          } else {
            AppLogger.debug('이메일 유효성 검사 통과', tag: 'ChangePasswordValidation');
          }
          state = state.copyWith(emailError: error);
        }

      case SendResetEmail():
        await _performResetPassword();

      case NavigateBack():
        AppLogger.debug('뒤로가기 액션 - Root에서 처리됨', tag: 'ChangePasswordNotifier');
        // Root에서 처리됨
        break;
    }
  }

  Future<void> _performResetPassword() async {
    final startTime = TimeFormatter.nowInSeoul();
    final maskedEmail = PrivacyMaskUtil.maskEmail(state.email);

    AppLogger.logBox('비밀번호 재설정 시도', '이메일: $maskedEmail');

    try {
      // 이메일 유효성 검증
      AppLogger.logStep(1, 3, '이메일 유효성 검증');
      final emailError = AuthValidator.validateEmail(state.email);
      state = state.copyWith(emailError: emailError);

      if (emailError != null) {
        AppLogger.warning(
          '이메일 유효성 검사 실패: $emailError',
          tag: 'ChangePasswordValidation',
        );
        return;
      }

      AppLogger.info('이메일 유효성 검사 통과', tag: 'ChangePasswordValidation');

      // 비밀번호 재설정 이메일 전송
      AppLogger.logStep(2, 3, '비밀번호 재설정 이메일 전송 시작');
      state = state.copyWith(
        resetPasswordResult: const AsyncLoading(),
        successMessage: null,
        formErrorMessage: null,
      );

      final result = await _resetPasswordUseCase.execute(state.email);

      // 결과 처리
      AppLogger.logStep(3, 3, '비밀번호 재설정 결과 처리');

      if (result.hasError) {
        final error = result.error;
        String errorMessage = AuthErrorMessages.passwordResetFailed;

        if (error is Failure) {
          switch (error.type) {
            case FailureType.validation:
              errorMessage = error.message;
              AppLogger.warning(
                '비밀번호 재설정 검증 오류: ${error.message}',
                tag: 'ChangePasswordReset',
              );
              break;
            case FailureType.network:
              errorMessage = AuthErrorMessages.networkError;
              AppLogger.error('비밀번호 재설정 네트워크 오류', tag: 'ChangePasswordReset');
              break;
            case FailureType.timeout:
              errorMessage = AuthErrorMessages.timeoutError;
              AppLogger.warning('비밀번호 재설정 타임아웃', tag: 'ChangePasswordReset');
              break;
            default:
              errorMessage = error.message;
              AppLogger.error(
                '비밀번호 재설정 기타 오류: ${error.type}',
                tag: 'ChangePasswordReset',
              );
          }
        }

        final duration = TimeFormatter.nowInSeoul().difference(startTime);
        AppLogger.logPerformance('비밀번호 재설정 실패', duration);

        AppLogger.error(
          '비밀번호 재설정 에러',
          tag: 'ChangePasswordReset',
          error: error,
        );

        state = state.copyWith(
          resetPasswordResult: result,
          formErrorMessage: errorMessage,
        );
      } else {
        final duration = TimeFormatter.nowInSeoul().difference(startTime);
        AppLogger.logPerformance('비밀번호 재설정 성공', duration);

        AppLogger.info(
          '비밀번호 재설정 이메일 발송 성공: $maskedEmail',
          tag: 'ChangePasswordReset',
        );

        state = state.copyWith(
          resetPasswordResult: result,
          successMessage: '비밀번호 재설정 이메일이 발송되었습니다.',
          formErrorMessage: null,
        );

        AppLogger.logState('비밀번호 재설정 완료', {
          'email': maskedEmail,
          'success': true,
          'duration': '${duration.inMilliseconds}ms',
        });
      }
    } catch (e, stackTrace) {
      final duration = TimeFormatter.nowInSeoul().difference(startTime);
      AppLogger.logPerformance('비밀번호 재설정 예외 발생', duration);

      AppLogger.error(
        '비밀번호 재설정 예외 발생',
        tag: 'ChangePasswordReset',
        error: e,
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        resetPasswordResult: AsyncError(e, stackTrace),
        formErrorMessage: AuthErrorMessages.passwordResetFailed,
      );
    }
  }

  void resetForm() {
    AppLogger.info('비밀번호 변경 폼 초기화', tag: 'ChangePasswordNotifier');
    state = const ChangePasswordState();
    AppLogger.debug('폼 상태 초기화 완료', tag: 'ChangePasswordNotifier');
  }
}
