// lib/auth/presentation/login/login_notifier.dart
import 'package:devlink_mobile_app/auth/domain/usecase/login_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/auth/presentation/login/login_action.dart';
import 'package:devlink_mobile_app/auth/presentation/login/login_state.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/auth_validator.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_notifier.g.dart';

@Riverpod(keepAlive: false)
class LoginNotifier extends _$LoginNotifier {
  late final LoginUseCase _loginUseCase;

  @override
  LoginState build() {
    _loginUseCase = ref.watch(loginUseCaseProvider);
    return const LoginState(loginUserResult: null);
  }

  Future<void> onAction(LoginAction action) async {
    switch (action) {
      case LoginPressed(:final email, :final password):
        await _handleLogin(email, password);
        break;

      case NavigateToForgetPassword():
        // Root에서 이동 처리 (UI context 이용 → Root 처리 예정)
        break;

      case NavigateToSignUp():
        // Root에서 이동 처리 (UI context 이용 → Root 처리 예정)
        break;
    }
  }

  Future<void> _handleLogin(String email, String password) async {
    // 입력값 기본 검증
    if (email.isEmpty && password.isEmpty) {
      state = state.copyWith(
        loginErrorMessage: AuthErrorMessages.formValidationFailed,
        loginUserResult: null,
      );
      return;
    }

    if (email.isEmpty) {
      state = state.copyWith(
        loginErrorMessage: AuthErrorMessages.emailRequired,
        loginUserResult: null,
      );
      return;
    }

    if (password.isEmpty) {
      state = state.copyWith(
        loginErrorMessage: AuthErrorMessages.passwordRequired,
        loginUserResult: null,
      );
      return;
    }

    // 이메일 형식 검증
    final emailError = AuthValidator.validateEmail(email);
    if (emailError != null) {
      state = state.copyWith(
        loginErrorMessage: emailError,
        loginUserResult: null,
      );
      return;
    }

    // 로딩 상태 설정
    state = state.copyWith(
      loginErrorMessage: null, // 기존 에러 메시지 초기화
      loginUserResult: const AsyncLoading(),
    );

    // 이메일 주소는 그대로 전달 - 소문자 변환은 Repository/DataSource 레벨에서 처리
    // 사용자가 입력한 이메일 주소 형식을 UI에서는 유지하고,
    // 로그인 처리 과정에서 소문자로 변환되어 비교됨
    final asyncResult = await _loginUseCase.execute(
      email: email, // 원본 이메일 그대로 전달
      password: password,
    );

    // 로그인 결과 처리
    if (asyncResult.hasError) {
      // 에러 발생 시 상세 로깅 (디버그 모드에서만)
      final error = asyncResult.error;
      debugPrint('로그인 에러: ${error.toString()}');

      // 에러 타입에 따른 사용자 친화적 메시지 처리
      String friendlyMessage = AuthErrorMessages.loginFailed;

      if (error is Failure) {
        switch (error.type) {
          case FailureType.unauthorized:
            friendlyMessage = error.message;
            break;
          case FailureType.network:
            friendlyMessage = AuthErrorMessages.networkError;
            break;
          case FailureType.timeout:
            friendlyMessage = AuthErrorMessages.timeoutError;
            break;
          default:
            friendlyMessage = error.message;
        }
      }

      // 친화적 메시지 설정 및 에러 상태 업데이트
      state = state.copyWith(
        loginErrorMessage: friendlyMessage,
        loginUserResult: asyncResult,
      );
    } else {
      // 성공 시 상태 업데이트 (에러 메시지 제거)

      state = state.copyWith(
        loginErrorMessage: null,
        loginUserResult: asyncResult,
      );
    }
  }

  void logout() {
    state = const LoginState();
  }
}
