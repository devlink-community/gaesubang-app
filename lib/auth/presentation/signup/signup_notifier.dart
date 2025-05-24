// lib/auth/presentation/signup/signup_notifier.dart

import 'package:devlink_mobile_app/auth/domain/usecase/core/check_email_availability_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/core/check_nickname_availability_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/core/login_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/core/signup_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/terms/get_terms_from_memory_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_action.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_state.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/auth_validator.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/privacy_mask_util.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'signup_notifier.g.dart';

@riverpod
class SignupNotifier extends _$SignupNotifier {
  late final SignupUseCase _signupUseCase;
  late final LoginUseCase _loginUseCase;
  late final CheckNicknameAvailabilityUseCase _checkNicknameAvailabilityUseCase;
  late final CheckEmailAvailabilityUseCase _checkEmailAvailabilityUseCase;
  late final GetTermsFromMemoryUseCase _getTermsFromMemoryUseCase;

  @override
  SignupState build() {
    AppLogger.authInfo('SignupNotifier 초기화 시작');

    _signupUseCase = ref.watch(signupUseCaseProvider);
    _loginUseCase = ref.watch(loginUseCaseProvider);
    _checkNicknameAvailabilityUseCase = ref.watch(
      checkNicknameAvailabilityUseCaseProvider,
    );
    _checkEmailAvailabilityUseCase = ref.watch(
      checkEmailAvailabilityUseCaseProvider,
    );
    _getTermsFromMemoryUseCase = ref.watch(getTermsFromMemoryUseCaseProvider);

    AppLogger.authInfo('SignupNotifier 초기화 완료');
    return const SignupState();
  }

  Future<void> onAction(SignupAction action) async {
    AppLogger.logStep(1, 1, '회원가입 액션 처리: ${action.runtimeType}');

    switch (action) {
      // 폼 입력값 변경 액션 처리
      case NicknameChanged(:final nickname):
        AppLogger.debug('닉네임 입력 변경: ${nickname.length}자');
        state = state.copyWith(
          nickname: nickname,
          nicknameError: null,
          nicknameSuccess: null,
          formErrorMessage: null,
        );

      case EmailChanged(:final email):
        AppLogger.debug('이메일 입력 변경: ${email.length}자');
        state = state.copyWith(
          email: email,
          emailError: null,
          emailSuccess: null,
          formErrorMessage: null,
        );

      case PasswordChanged(:final password):
        AppLogger.debug('비밀번호 입력 변경: ${password.length}자');
        state = state.copyWith(
          password: password,
          passwordError: null,
          formErrorMessage: null,
          // 비밀번호가 변경되면 비밀번호 확인 유효성도 다시 검증
          passwordConfirmError:
              state.passwordConfirm.isEmpty
                  ? null
                  : AuthValidator.validatePasswordConfirm(
                    password,
                    state.passwordConfirm,
                  ),
        );

      case PasswordConfirmChanged(:final passwordConfirm):
        AppLogger.debug('비밀번호 확인 입력 변경: ${passwordConfirm.length}자');
        state = state.copyWith(
          passwordConfirm: passwordConfirm,
          passwordConfirmError: null,
          formErrorMessage: null,
        );

      case AgreeToTermsChanged(:final agree):
        AppLogger.authInfo('약관 동의 체크박스 변경: $agree');
        state = state.copyWith(
          agreeToTerms: agree,
          termsError: null,
          formErrorMessage: null,
        );

        // 체크박스가 체크되면 자동으로 약관에 동의 처리
        if (agree) {
          AppLogger.authInfo('자동 약관 동의 처리 시작');
          await _autoAgreeToTerms();
        } else {
          AppLogger.authInfo('약관 동의 해제 - 상태 초기화');
          // 체크 해제된 경우 약관 동의 상태 초기화
          state = state.copyWith(agreedTermsId: null, isTermsAgreed: false);
        }

      // 포커스 변경 액션 처리 (필드 유효성 검증)
      case NicknameFocusChanged(:final hasFocus):
        if (!hasFocus && state.nickname.isNotEmpty) {
          AppLogger.debug('닉네임 필드 포커스 아웃 - 유효성 검증 시작');
          // 포커스를 잃을 때만 유효성 검증
          final error = AuthValidator.validateNickname(state.nickname);
          state = state.copyWith(nicknameError: error, formErrorMessage: null);

          // 닉네임이 유효하면 중복 확인
          if (error == null) {
            AppLogger.debug('닉네임 유효성 검증 통과 - 중복 확인 진행');
            await _performNicknameAvailabilityCheck();
          } else {
            AppLogger.warning('닉네임 유효성 검증 실패', error: error);
          }
        }

      case EmailFocusChanged(:final hasFocus):
        if (!hasFocus && state.email.isNotEmpty) {
          AppLogger.debug('이메일 필드 포커스 아웃 - 유효성 검증 시작');
          // 포커스를 잃을 때만 유효성 검증
          final error = AuthValidator.validateEmail(state.email);
          state = state.copyWith(emailError: error, formErrorMessage: null);

          // 이메일이 유효하면 중복 확인, 형식 오류면 중복 확인 건너뜀
          if (error == null) {
            AppLogger.debug('이메일 유효성 검증 통과 - 중복 확인 진행');
            await _performEmailAvailabilityCheck();
          } else {
            AppLogger.warning('이메일 유효성 검증 실패', error: error);
            // 형식 오류가 있는 경우 중복 확인 결과 초기화
            state = state.copyWith(emailAvailability: null, emailSuccess: null);
          }
        }

      case PasswordFocusChanged(:final hasFocus):
        if (!hasFocus && state.password.isNotEmpty) {
          AppLogger.debug('비밀번호 필드 포커스 아웃 - 유효성 검증 시작');
          // 포커스를 잃을 때만 유효성 검증
          final error = AuthValidator.validatePassword(state.password);
          state = state.copyWith(passwordError: error, formErrorMessage: null);

          if (error != null) {
            AppLogger.warning('비밀번호 유효성 검증 실패', error: error);
          }
        }

      case PasswordConfirmFocusChanged(:final hasFocus):
        if (!hasFocus && state.passwordConfirm.isNotEmpty) {
          AppLogger.debug('비밀번호 확인 필드 포커스 아웃 - 유효성 검증 시작');
          // 포커스를 잃을 때만 유효성 검증
          final error = AuthValidator.validatePasswordConfirm(
            state.password,
            state.passwordConfirm,
          );
          state = state.copyWith(
            passwordConfirmError: error,
            formErrorMessage: null,
          );

          if (error != null) {
            AppLogger.warning('비밀번호 확인 유효성 검증 실패', error: error);
          }
        }

      // 중복 확인 액션 처리
      case CheckNicknameAvailability():
        AppLogger.authInfo('수동 닉네임 중복 확인 요청');
        await _performNicknameAvailabilityCheck();

      case CheckEmailAvailability():
        AppLogger.authInfo('수동 이메일 중복 확인 요청');
        await _performEmailAvailabilityCheck();

      // 회원가입 제출 액션 처리
      case Submit():
        AppLogger.logBanner('회원가입 제출 시작');
        await _performSignup();

      // 화면 이동 액션은 Root에서 처리됨
      case NavigateToLogin():
      case NavigateToTerms():
        AppLogger.navigation('화면 이동 액션: ${action.runtimeType} (Root에서 처리)');
        // Root에서 처리됨
        break;
    }
  }

  // 체크박스를 통한 약관 자동 동의 처리
  Future<void> _autoAgreeToTerms() async {
    AppLogger.logStep(1, 3, '약관 자동 동의 처리 시작');

    // 이미 약관에 동의한 상태라면 다시 처리하지 않음
    if (state.isTermsAgreed) {
      AppLogger.debug('이미 약관 동의 완료 상태 - 처리 건너뜀');
      return;
    }

    try {
      AppLogger.logStep(2, 3, '약관 정보 조회 중');
      // 새 약관 정보 생성
      final termsResult = await _getTermsFromMemoryUseCase.execute();

      if (termsResult.hasValue && termsResult.value != null) {
      } else {
        AppLogger.error('약관 정보 조회 실패', error: termsResult.error);
        state = state.copyWith(
          agreeToTerms: false,
          formErrorMessage: AuthErrorMessages.termsProcessFailed,
        );
      }
    } catch (e, st) {
      AppLogger.error('약관 자동 동의 오류', error: e, stackTrace: st);
      // 오류 발생 시 체크박스 상태를 원래대로 되돌림
      state = state.copyWith(
        agreeToTerms: false,
        formErrorMessage: AuthErrorMessages.termsProcessError,
      );
    }
  }

  // 닉네임 중복 확인
  Future<void> _performNicknameAvailabilityCheck() async {
    AppLogger.logStep(1, 3, '닉네임 중복 확인 시작: ${state.nickname}');

    // 중복 확인 전에 먼저 닉네임 유효성 검사
    final nicknameError = AuthValidator.validateNickname(state.nickname);

    if (nicknameError != null) {
      AppLogger.warning('닉네임 유효성 검사 실패 - 중복 확인 중단', error: nicknameError);
      // 유효성 검사 실패 시 에러 메시지 설정하고 중복 확인 하지 않음
      state = state.copyWith(
        nicknameError: nicknameError,
        nicknameSuccess: null,
        nicknameAvailability: null, // 중복 확인 결과 초기화
        formErrorMessage: null,
      );
      return; // 유효성 검사 실패로 중복 확인 중단
    }

    AppLogger.logStep(2, 3, '닉네임 유효성 검사 통과 - API 호출 시작');
    // 유효성 검사 통과 후 중복 확인 진행
    state = state.copyWith(
      nicknameAvailability: const AsyncValue.loading(),
      nicknameSuccess: null,
      nicknameError: null, // 유효성 검사 통과했으므로 에러 초기화
      formErrorMessage: null,
    );

    final result = await _checkNicknameAvailabilityUseCase.execute(
      state.nickname,
    );

    AppLogger.logStep(3, 3, '닉네임 중복 확인 API 응답 처리');
    // 결과에 따라 에러 또는 성공 메시지 설정
    if (result.hasValue && result.value == true) {
      // 사용 가능한 경우
      AppLogger.authInfo('닉네임 사용 가능: ${state.nickname}');
      state = state.copyWith(
        nicknameAvailability: result,
        nicknameError: null,
        nicknameSuccess: AuthErrorMessages.nicknameSuccess,
        formErrorMessage: null,
      );
    } else {
      // 사용 불가능하거나 에러가 발생한 경우
      final errorMessage =
          result.hasError
              ? AuthErrorMessages.nicknameCheckFailed
              : AuthErrorMessages.nicknameAlreadyInUse;

      AppLogger.warning(
        '닉네임 중복 확인 실패: ${state.nickname}',
        error: result.hasError ? result.error : '이미 사용 중',
      );

      state = state.copyWith(
        nicknameAvailability: result,
        nicknameError: errorMessage,
        nicknameSuccess: null,
        formErrorMessage: null,
      );
    }
  }

  // 이메일 중복 확인
  Future<void> _performEmailAvailabilityCheck() async {
    AppLogger.logStep(1, 3, '이메일 중복 확인 시작: ${state.email}');

    // 중복 확인 전에 먼저 이메일 유효성 검사
    final emailError = AuthValidator.validateEmail(state.email);

    if (emailError != null) {
      AppLogger.warning('이메일 유효성 검사 실패 - 중복 확인 중단', error: emailError);
      // 유효성 검사 실패 시 에러 메시지 설정하고 중복 확인 하지 않음
      state = state.copyWith(
        emailError: emailError,
        emailSuccess: null,
        emailAvailability: null, // 중복 확인 결과 초기화
        formErrorMessage: null,
      );
      return; // 유효성 검사 실패로 중복 확인 중단
    }

    AppLogger.logStep(2, 3, '이메일 유효성 검사 통과 - API 호출 시작');
    // 유효성 검사 통과 후 중복 확인 진행
    state = state.copyWith(
      emailAvailability: const AsyncValue.loading(),
      emailSuccess: null,
      emailError: null, // 유효성 검사 통과했으므로 에러 초기화
      formErrorMessage: null,
    );

    final result = await _checkEmailAvailabilityUseCase.execute(state.email);

    AppLogger.logStep(3, 3, '이메일 중복 확인 API 응답 처리');
    // 결과에 따라 에러 또는 성공 메시지 설정
    if (result.hasValue && result.value == true) {
      // 사용 가능한 경우
      AppLogger.authInfo('이메일 사용 가능: ${state.email}');
      state = state.copyWith(
        emailAvailability: result,
        emailError: null,
        emailSuccess: AuthErrorMessages.emailSuccess,
        formErrorMessage: null,
      );
    } else if (result.hasValue && result.value == false) {
      // 사용 불가능한 경우 (중복된 이메일)
      AppLogger.warning('이메일 중복: ${state.email}');
      state = state.copyWith(
        emailAvailability: result,
        emailError: AuthErrorMessages.emailAlreadyInUse,
        emailSuccess: null,
        formErrorMessage: null,
      );
    } else {
      // 오류 발생 시 에러 메시지를 표시하지 않고 결과 초기화
      AppLogger.error('이메일 중복 확인 중 오류 발생', error: result.error);

      state = state.copyWith(
        emailAvailability: null,
        emailSuccess: null,
        formErrorMessage: null,
      );
    }
  }

  // 회원가입 실행 (자동 로그인 포함)
  Future<void> _performSignup() async {
    final startTime = DateTime.now();
    AppLogger.logBanner('회원가입 프로세스 시작');

    // 폼 전체 오류 메시지 초기화
    state = state.copyWith(formErrorMessage: null);

    AppLogger.logStep(1, 6, '폼 유효성 검증 시작');
    // 1. 모든 필드의 유효성 검증 (AuthValidator 사용)
    final nicknameError = AuthValidator.validateNickname(state.nickname);
    final emailError = AuthValidator.validateEmail(state.email);
    final passwordError = AuthValidator.validatePassword(state.password);
    final passwordConfirmError = AuthValidator.validatePasswordConfirm(
      state.password,
      state.passwordConfirm,
    );
    final termsError = AuthValidator.validateTermsAgreement(
      state.agreeToTerms || state.isTermsAgreed,
    );

    AppLogger.logState('폼 유효성 검증 결과', {
      'nickname_valid': nicknameError == null,
      'email_valid': emailError == null,
      'password_valid': passwordError == null,
      'password_confirm_valid': passwordConfirmError == null,
      'terms_valid': termsError == null,
    });

    // 검증 결과 업데이트
    state = state.copyWith(
      nicknameError: nicknameError,
      emailError: emailError,
      passwordError: passwordError,
      passwordConfirmError: passwordConfirmError,
      termsError: termsError,
    );

    // 약관 동의 오류가 있는 경우 다른 오류 메시지는 표시하지 않음
    if (termsError != null) {
      AppLogger.warning('약관 동의 필요 - 회원가입 중단');
      return;
    }

    // 유효성 검증 오류가 있으면 통합 오류 메시지 설정 및 회원가입 진행 중단
    if (nicknameError != null ||
        emailError != null ||
        passwordError != null ||
        passwordConfirmError != null) {
      AppLogger.warning('폼 유효성 검증 실패 - 회원가입 중단');
      state = state.copyWith(
        formErrorMessage: AuthErrorMessages.formValidationFailed,
      );
      return;
    }

    AppLogger.logStep(2, 6, '중복 확인 검증 시작');
    // 2. 닉네임, 이메일 중복 확인
    if (state.nicknameAvailability?.value != true) {
      AppLogger.debug('닉네임 중복 확인 재실행');
      await _performNicknameAvailabilityCheck();
    }

    if (state.emailAvailability?.value != true) {
      AppLogger.debug('이메일 중복 확인 재실행');
      await _performEmailAvailabilityCheck();
    }

    // 중복 확인 결과가 유효하지 않으면 회원가입 진행 중단
    if (state.nicknameAvailability?.value != true ||
        state.emailAvailability?.value != true) {
      AppLogger.warning('중복 확인 실패 - 회원가입 중단');
      state = state.copyWith(
        formErrorMessage: AuthErrorMessages.duplicateCheckRequired,
      );
      return;
    }

    AppLogger.logStep(3, 6, '회원가입 API 호출 시작');
    AppLogger.logState('회원가입 요청 정보', {
      'email': PrivacyMaskUtil.maskEmail(state.email), // 변경
      'nickname': PrivacyMaskUtil.maskNickname(state.nickname), // 변경
      'password_length': state.password.length,
      'agreed_terms_id': state.agreedTermsId,
      'is_terms_agreed': state.isTermsAgreed,
    });

    // 3. 회원가입 실행
    state = state.copyWith(
      signupResult: const AsyncValue.loading(),
      formErrorMessage: null, // 회원가입 시작 시 폼 에러 메시지 클리어
    );

    final signupResult = await _signupUseCase.execute(
      email: state.email,
      password: state.password,
      nickname: state.nickname,
      agreedTermsId: state.agreedTermsId,
    );

    AppLogger.logStep(4, 6, '회원가입 API 응답 처리');
    // 회원가입 성공 시 자동 로그인 수행
    if (signupResult.hasValue) {
      AppLogger.authInfo('회원가입 성공 - 자동 로그인 시작');

      AppLogger.logStep(5, 6, '자동 로그인 수행 중');
      // 자동 로그인 수행
      final loginResult = await _loginUseCase.execute(
        email: state.email,
        password: state.password,
      );

      if (loginResult.hasValue) {
        AppLogger.logStep(6, 6, '자동 로그인 성공 - 회원가입 완료');
        final duration = DateTime.now().difference(startTime);
        AppLogger.logPerformance('전체 회원가입 프로세스', duration);

        AppLogger.logBox(
          '회원가입 성공',
          '사용자: ${PrivacyMaskUtil.maskNickname(state.nickname)}\n이메일: ${PrivacyMaskUtil.maskEmail(state.email)}\n소요시간: ${duration.inSeconds}초', // 변경
        );

        // 로그인 성공 결과를 signupResult에 설정
        state = state.copyWith(signupResult: loginResult);
      } else {
        AppLogger.error('자동 로그인 실패', error: loginResult.error);
        // 자동 로그인 실패 시에도 회원가입은 성공했으므로 성공 처리
        state = state.copyWith(signupResult: signupResult);
      }
    } else {
      // 회원가입 실패
      AppLogger.error('회원가입 실패', error: signupResult.error);
      AppLogger.logState('회원가입 실패 상세', {
        'error_type': signupResult.error.runtimeType.toString(),
        'error_message': signupResult.error.toString(),
        'email': state.email,
        'nickname': state.nickname,
      });

      state = state.copyWith(signupResult: signupResult);
    }
  }

  // 폼 리셋 (회원가입 성공 후 호출)
  void resetForm() {
    AppLogger.debug('회원가입 폼 리셋');
    state = const SignupState();
  }

  // 약관 동의 ID 설정
  void setAgreedTermsId(String termsId) {
    AppLogger.authInfo('약관 동의 ID 설정: $termsId');
    state = state.copyWith(agreedTermsId: termsId, formErrorMessage: null);
  }

  // 약관 동의 상태 업데이트
  void updateTermsAgreement({
    required String? agreedTermsId,
    required bool isAgreed,
  }) {
    AppLogger.logState('약관 동의 상태 업데이트', {
      'agreed_terms_id': agreedTermsId,
      'is_agreed': isAgreed,
    });

    state = state.copyWith(
      agreedTermsId: agreedTermsId,
      isTermsAgreed: isAgreed,
      termsError: null, // 약관 에러 메시지 초기화 추가
      formErrorMessage: null, // 통합 에러 메시지도 초기화
    );
  }
}
