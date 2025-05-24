// lib/auth/presentation/login/login_notifier.dart
import 'package:devlink_mobile_app/auth/domain/usecase/login_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/auth/presentation/login/login_action.dart';
import 'package:devlink_mobile_app/auth/presentation/login/login_state.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/auth_validator.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/privacy_mask_util.dart';
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
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
    AppLogger.debug(
      'LoginAction 수신: ${action.runtimeType}',
      tag: 'LoginNotifier',
    );

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
    final maskedEmail = PrivacyMaskUtil.maskEmail(email);
    final startTime = DateTime.now();

    AppLogger.logBox('로그인 시도', '이메일: $maskedEmail');

    try {
      // 1. 입력값 기본 검증
      AppLogger.logStep(1, 4, '입력값 유효성 검사');
      final validationResult = _validateLoginInput(email, password);
      if (validationResult != null) {
        AppLogger.warning(
          '로그인 입력값 검증 실패: $validationResult',
          tag: 'LoginValidation',
        );

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
        AppLogger.warning(
          '이메일 형식 오류: $emailError',
          tag: 'LoginValidation',
        );

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

      AppLogger.error(
        '로그인 처리 중 예외 발생',
        tag: 'LoginProcess',
        error: e,
        stackTrace: st,
      );

      state = state.copyWith(
        loginErrorMessage: AuthErrorMessages.loginFailed,
        loginUserResult: AsyncError(e, st),
      );
    }
  }

  /// 로그인 입력값 검증
  String? _validateLoginInput(String email, String password) {
    AppLogger.debug(
      '입력값 검증 시작',
      tag: 'LoginValidation',
    );

    if (email.isEmpty && password.isEmpty) {
      AppLogger.debug(
        '이메일과 비밀번호 모두 비어있음',
        tag: 'LoginValidation',
      );
      return AuthErrorMessages.formValidationFailed;
    }

    if (email.isEmpty) {
      AppLogger.debug(
        '이메일이 비어있음',
        tag: 'LoginValidation',
      );
      return AuthErrorMessages.emailRequired;
    }

    if (password.isEmpty) {
      AppLogger.debug(
        '비밀번호가 비어있음',
        tag: 'LoginValidation',
      );
      return AuthErrorMessages.passwordRequired;
    }

    AppLogger.debug(
      '입력값 검증 통과',
      tag: 'LoginValidation',
    );

    return null;
  }

  /// 로그인 결과 처리 (AsyncValue 기반)
  void _processLoginResult(AsyncValue<Member> asyncResult, String email) {
    final startTime = DateTime.now();
    final maskedEmail = PrivacyMaskUtil.maskEmail(email);

    AppLogger.debug(
      '로그인 결과 처리 시작',
      tag: 'LoginProcess',
    );

    // AsyncValue의 hasError와 hasValue 사용
    if (asyncResult.hasError) {
      // ✅ 에러 발생 시 처리
      final error = asyncResult.error;

      AppLogger.error(
        '로그인 실패',
        tag: 'LoginProcess',
        error: error,
      );

      // 에러 타입에 따른 사용자 친화적 메시지 처리
      String friendlyMessage = AuthErrorMessages.loginFailed;

      if (error is Failure) {
        switch (error.type) {
          case FailureType.unauthorized:
            friendlyMessage = error.message;
            AppLogger.warning(
              '로그인 인증 실패: $maskedEmail',
              tag: 'LoginAuth',
            );
            break;
          case FailureType.network:
            friendlyMessage = AuthErrorMessages.networkError;
            AppLogger.networkError('로그인 네트워크 오류');
            break;
          case FailureType.timeout:
            friendlyMessage = AuthErrorMessages.timeoutError;
            AppLogger.warning(
              '로그인 타임아웃',
              tag: 'LoginProcess',
            );
            break;
          default:
            friendlyMessage = error.message;
            AppLogger.error(
              '기타 로그인 오류: ${error.type}',
              tag: 'LoginProcess',
            );
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
      AppLogger.authInfo('로그인 성공: $maskedEmail');

      // 개인정보 보호를 위한 안전한 로깅
      final safeUserInfo = PrivacyMaskUtil.createSafeUserInfo(
        userId: member.uid,
        email: email,
        nickname: member.nickname,
        additionalInfo: {
          'streakDays': member.streakDays,
          'totalFocusMinutes': member.focusStats?.totalMinutes ?? 0,
        },
      );

      AppLogger.logState('LoginSuccess', safeUserInfo);
    }
  }

  void logout() {
    AppLogger.authInfo('로그아웃 요청');

    state = const LoginState();

    AppLogger.authInfo('로그인 상태 초기화 완료');
  }
}
