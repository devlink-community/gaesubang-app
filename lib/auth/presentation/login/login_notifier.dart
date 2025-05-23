// lib/auth/presentation/login/login_notifier.dart
import 'package:devlink_mobile_app/auth/domain/usecase/login_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/auth/presentation/login/login_action.dart';
import 'package:devlink_mobile_app/auth/presentation/login/login_state.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/auth_validator.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_notifier.g.dart';

@Riverpod(keepAlive: false)
class LoginNotifier extends _$LoginNotifier {
  late final LoginUseCase _loginUseCase;

  @override
  LoginState build() {
    _loginUseCase = ref.watch(loginUseCaseProvider);
    AppLogger.authInfo('LoginNotifier 초기화 완료');
    return const LoginState(loginUserResult: null);
  }

  Future<void> onAction(LoginAction action) async {
    AppLogger.debug('LoginAction 수신: ${action.runtimeType}');

    switch (action) {
      case LoginPressed(:final email, :final password):
        await _handleLogin(email, password);
        break;

      case NavigateToForgetPassword():
        AppLogger.navigation('비밀번호 찾기 화면으로 이동');
        // Root에서 이동 처리 (UI context 이용 → Root 처리 예정)
        break;

      case NavigateToSignUp():
        AppLogger.navigation('회원가입 화면으로 이동');
        // Root에서 이동 처리 (UI context 이용 → Root 처리 예정)
        break;
    }
  }

  Future<void> _handleLogin(String email, String password) async {
    AppLogger.logBox('로그인 시도', '이메일: ${_maskEmail(email)}');
    final startTime = DateTime.now();

    try {
      // 1. 입력값 기본 검증
      AppLogger.logStep(1, 4, '입력값 유효성 검사');
      final validationResult = _validateLoginInput(email, password);
      if (validationResult != null) {
        AppLogger.warning('로그인 입력값 검증 실패: $validationResult');
        state = state.copyWith(
          loginErrorMessage: validationResult,
          loginUserResult: null,
        );
        return;
      }

      // 2. 이메일 형식 검증
      AppLogger.logStep(2, 4, '이메일 형식 검증');
      final emailError = AuthValidator.validateEmail(email);
      if (emailError != null) {
        AppLogger.warning('이메일 형식 오류: $emailError');
        state = state.copyWith(
          loginErrorMessage: emailError,
          loginUserResult: null,
        );
        return;
      }

      // 3. 로딩 상태 설정
      AppLogger.logStep(3, 4, '로그인 프로세스 시작');
      state = state.copyWith(
        loginErrorMessage: null, // 기존 에러 메시지 초기화
        loginUserResult: const AsyncLoading(),
      );

      // 4. 로그인 수행 (UseCase는 AsyncValue<Member> 반환)
      final asyncResult = await _loginUseCase.execute(
        email: email, // 원본 이메일 그대로 전달
        password: password,
      );

      // 5. 결과 처리
      AppLogger.logStep(4, 4, '로그인 결과 처리');
      _processLoginResult(asyncResult, email);
    } catch (e, st) {
      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('로그인 처리 실패', duration);
      AppLogger.error('로그인 처리 중 예외 발생', error: e, stackTrace: st);

      state = state.copyWith(
        loginErrorMessage: AuthErrorMessages.loginFailed,
        loginUserResult: AsyncError(e, st),
      );
    }
  }

  /// 로그인 입력값 검증
  String? _validateLoginInput(String email, String password) {
    if (email.isEmpty && password.isEmpty) {
      return AuthErrorMessages.formValidationFailed;
    }
    if (email.isEmpty) {
      return AuthErrorMessages.emailRequired;
    }
    if (password.isEmpty) {
      return AuthErrorMessages.passwordRequired;
    }
    return null;
  }

  /// 로그인 결과 처리 (AsyncValue 기반)
  void _processLoginResult(AsyncValue<Member> asyncResult, String email) {
    final startTime = DateTime.now();

    // AsyncValue의 hasError와 hasValue 사용
    if (asyncResult.hasError) {
      // ✅ 에러 발생 시 처리
      final error = asyncResult.error;
      AppLogger.error('로그인 실패', error: error);

      // 에러 타입에 따른 사용자 친화적 메시지 처리
      String friendlyMessage = AuthErrorMessages.loginFailed;

      if (error is Failure) {
        switch (error.type) {
          case FailureType.unauthorized:
            friendlyMessage = error.message;
            AppLogger.warning('로그인 인증 실패: ${_maskEmail(email)}');
            break;
          case FailureType.network:
            friendlyMessage = AuthErrorMessages.networkError;
            AppLogger.networkError('로그인 네트워크 오류');
            break;
          case FailureType.timeout:
            friendlyMessage = AuthErrorMessages.timeoutError;
            AppLogger.warning('로그인 타임아웃');
            break;
          default:
            friendlyMessage = error.message;
            AppLogger.error('기타 로그인 오류: ${error.type}');
        }
      }

      // 에러 상태 업데이트
      state = state.copyWith(
        loginErrorMessage: friendlyMessage,
        loginUserResult: asyncResult, // AsyncError 그대로 사용
      );

      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('로그인 실패 처리', duration);
    } else if (asyncResult.hasValue) {
      // ✅ 성공 시 처리
      final member = asyncResult.value!;

      state = state.copyWith(
        loginErrorMessage: null,
        loginUserResult: asyncResult, // AsyncData 그대로 사용
      );

      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('로그인 성공 처리', duration);
      AppLogger.logBanner('로그인 성공! 🎉');
      AppLogger.authInfo('로그인 성공: ${_maskEmail(email)}');
      AppLogger.logState('LoginSuccess', {
        'userId': member.uid,
        'nickname': member.nickname,
        'email': _maskEmail(email),
        'streakDays': member.streakDays,
        'totalFocusMinutes': member.focusStats?.totalMinutes ?? 0,
      });
    }
  }

  /// 이메일 마스킹 (로깅용)
  String _maskEmail(String email) {
    if (email.length <= 3) return email;
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 3) {
      return '$username***@$domain';
    }

    return '${username.substring(0, 3)}***@$domain';
  }

  void logout() {
    AppLogger.authInfo('로그아웃 요청');
    state = const LoginState();
    AppLogger.authInfo('로그인 상태 초기화 완료');
  }
}
