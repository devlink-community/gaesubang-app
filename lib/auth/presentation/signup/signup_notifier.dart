// lib/auth/presentation/signup/signup_notifier.dart

import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/check_email_availability_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/check_nickname_availability_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/get_terms_info_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/login_use_case.dart'; // 🔥 추가
import 'package:devlink_mobile_app/auth/domain/usecase/save_terms_agreement_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/signup_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_action.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_state.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/auth_validator.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'signup_notifier.g.dart';

@riverpod
class SignupNotifier extends _$SignupNotifier {
  late final SignupUseCase _signupUseCase;
  late final LoginUseCase _loginUseCase; // 🔥 추가
  late final CheckNicknameAvailabilityUseCase _checkNicknameAvailabilityUseCase;
  late final CheckEmailAvailabilityUseCase _checkEmailAvailabilityUseCase;
  late final GetTermsInfoUseCase _getTermsInfoUseCase;
  late final SaveTermsAgreementUseCase _saveTermsAgreementUseCase;

  @override
  SignupState build() {
    _signupUseCase = ref.watch(signupUseCaseProvider);
    _loginUseCase = ref.watch(loginUseCaseProvider); // 🔥 추가
    _checkNicknameAvailabilityUseCase = ref.watch(
      checkNicknameAvailabilityUseCaseProvider,
    );
    _checkEmailAvailabilityUseCase = ref.watch(
      checkEmailAvailabilityUseCaseProvider,
    );
    _getTermsInfoUseCase = ref.watch(getTermsInfoUseCaseProvider);
    _saveTermsAgreementUseCase = ref.watch(saveTermsAgreementUseCaseProvider);

    return const SignupState();
  }

  Future<void> onAction(SignupAction action) async {
    switch (action) {
      // 폼 입력값 변경 액션 처리
      case NicknameChanged(:final nickname):
        state = state.copyWith(
          nickname: nickname,
          nicknameError: null,
          nicknameSuccess: null,
          formErrorMessage: null,
        );

      case EmailChanged(:final email):
        state = state.copyWith(
          email: email,
          emailError: null,
          emailSuccess: null,
          formErrorMessage: null,
        );

      case PasswordChanged(:final password):
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
        state = state.copyWith(
          passwordConfirm: passwordConfirm,
          passwordConfirmError: null,
          formErrorMessage: null,
        );

      case AgreeToTermsChanged(:final agree):
        state = state.copyWith(
          agreeToTerms: agree,
          termsError: null,
          formErrorMessage: null,
        );

        // 체크박스가 체크되면 자동으로 약관에 동의 처리
        if (agree) {
          await _autoAgreeToTerms();
        } else {
          // 체크 해제된 경우 약관 동의 상태 초기화
          state = state.copyWith(agreedTermsId: null, isTermsAgreed: false);
        }

      // 포커스 변경 액션 처리 (필드 유효성 검증)
      case NicknameFocusChanged(:final hasFocus):
        if (!hasFocus && state.nickname.isNotEmpty) {
          // 포커스를 잃을 때만 유효성 검증
          final error = AuthValidator.validateNickname(state.nickname);
          state = state.copyWith(nicknameError: error, formErrorMessage: null);

          // 닉네임이 유효하면 중복 확인
          if (error == null) {
            await _performNicknameAvailabilityCheck();
          }
        }

      case EmailFocusChanged(:final hasFocus):
        if (!hasFocus && state.email.isNotEmpty) {
          // 포커스를 잃을 때만 유효성 검증
          final error = AuthValidator.validateEmail(state.email);
          state = state.copyWith(emailError: error, formErrorMessage: null);

          // 이메일이 유효하면 중복 확인, 형식 오류면 중복 확인 건너뜀
          if (error == null) {
            await _performEmailAvailabilityCheck();
          } else {
            // 형식 오류가 있는 경우 중복 확인 결과 초기화
            state = state.copyWith(emailAvailability: null, emailSuccess: null);
          }
        }

      case PasswordFocusChanged(:final hasFocus):
        if (!hasFocus && state.password.isNotEmpty) {
          // 포커스를 잃을 때만 유효성 검증
          final error = AuthValidator.validatePassword(state.password);
          state = state.copyWith(passwordError: error, formErrorMessage: null);
        }

      case PasswordConfirmFocusChanged(:final hasFocus):
        if (!hasFocus && state.passwordConfirm.isNotEmpty) {
          // 포커스를 잃을 때만 유효성 검증
          final error = AuthValidator.validatePasswordConfirm(
            state.password,
            state.passwordConfirm,
          );
          state = state.copyWith(
            passwordConfirmError: error,
            formErrorMessage: null,
          );
        }

      // 중복 확인 액션 처리
      case CheckNicknameAvailability():
        await _performNicknameAvailabilityCheck();

      case CheckEmailAvailability():
        await _performEmailAvailabilityCheck();

      // 회원가입 제출 액션 처리
      case Submit():
        await _performSignup();

      // 화면 이동 액션은 Root에서 처리됨
      case NavigateToLogin():
      case NavigateToTerms():
        // Root에서 처리됨
        break;
    }
  }

  // 체크박스를 통한 약관 자동 동의 처리
  Future<void> _autoAgreeToTerms() async {
    // 이미 약관에 동의한 상태라면 다시 처리하지 않음
    if (state.isTermsAgreed) {
      return;
    }

    try {
      // 새 약관 정보 생성
      final termsResult = await _getTermsInfoUseCase.execute(null);

      if (termsResult.hasValue && termsResult.value != null) {
        final termsId = termsResult.value!.id;

        // 모든 약관에 동의하는 TermsAgreement 객체 생성
        final termsAgreement = TermsAgreement(
          id: termsId,
          isAllAgreed: true,
          isServiceTermsAgreed: true,
          isPrivacyPolicyAgreed: true,
          isMarketingAgreed: true,
          agreedAt: DateTime.now(),
        );

        // 약관 동의 저장
        final saveResult = await _saveTermsAgreementUseCase.execute(
          termsAgreement,
        );

        if (saveResult.hasValue) {
          // 약관 동의 상태 업데이트
          state = state.copyWith(
            agreedTermsId: termsId,
            isTermsAgreed: true,
            termsError: null,
          );

          debugPrint('약관 자동 동의 완료: $termsId');
        } else {
          debugPrint('약관 저장 실패: ${saveResult.error}');
          // 실패 시 체크박스 상태를 원래대로 되돌림
          state = state.copyWith(
            agreeToTerms: false,
            formErrorMessage: AuthErrorMessages.termsProcessFailed,
          );
        }
      }
    } catch (e) {
      debugPrint('약관 자동 동의 오류: $e');
      // 오류 발생 시 체크박스 상태를 원래대로 되돌림
      state = state.copyWith(
        agreeToTerms: false,
        formErrorMessage: AuthErrorMessages.termsProcessError,
      );
    }
  }

  // 닉네임 중복 확인
  Future<void> _performNicknameAvailabilityCheck() async {
    // 🔥 중복 확인 전에 먼저 닉네임 유효성 검사
    final nicknameError = AuthValidator.validateNickname(state.nickname);

    if (nicknameError != null) {
      // 유효성 검사 실패 시 에러 메시지 설정하고 중복 확인 하지 않음
      state = state.copyWith(
        nicknameError: nicknameError,
        nicknameSuccess: null,
        nicknameAvailability: null, // 중복 확인 결과 초기화
        formErrorMessage: null,
      );
      return; // 유효성 검사 실패로 중복 확인 중단
    }

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

    // 결과에 따라 에러 또는 성공 메시지 설정
    if (result.hasValue && result.value == true) {
      // 사용 가능한 경우
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
    // 🔥 중복 확인 전에 먼저 이메일 유효성 검사
    final emailError = AuthValidator.validateEmail(state.email);

    if (emailError != null) {
      // 유효성 검사 실패 시 에러 메시지 설정하고 중복 확인 하지 않음
      state = state.copyWith(
        emailError: emailError,
        emailSuccess: null,
        emailAvailability: null, // 중복 확인 결과 초기화
        formErrorMessage: null,
      );
      return; // 유효성 검사 실패로 중복 확인 중단
    }

    // 유효성 검사 통과 후 중복 확인 진행
    state = state.copyWith(
      emailAvailability: const AsyncValue.loading(),
      emailSuccess: null,
      emailError: null, // 유효성 검사 통과했으므로 에러 초기화
      formErrorMessage: null,
    );

    final result = await _checkEmailAvailabilityUseCase.execute(state.email);

    // 결과에 따라 에러 또는 성공 메시지 설정
    if (result.hasValue && result.value == true) {
      // 사용 가능한 경우
      state = state.copyWith(
        emailAvailability: result,
        emailError: null,
        emailSuccess: AuthErrorMessages.emailSuccess,
        formErrorMessage: null,
      );
    } else if (result.hasValue && result.value == false) {
      // 사용 불가능한 경우 (중복된 이메일)
      state = state.copyWith(
        emailAvailability: result,
        emailError: AuthErrorMessages.emailAlreadyInUse,
        emailSuccess: null,
        formErrorMessage: null,
      );
    } else {
      // 오류 발생 시 에러 메시지를 표시하지 않고 결과 초기화
      debugPrint('이메일 중복 확인 중 오류 발생: ${result.error}');

      state = state.copyWith(
        emailAvailability: null,
        emailSuccess: null,
        formErrorMessage: null,
      );
    }
  }

  // 🔥 회원가입 실행 (자동 로그인 포함)
  Future<void> _performSignup() async {
    // 폼 전체 오류 메시지 초기화
    state = state.copyWith(formErrorMessage: null);

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
      return;
    }

    // 유효성 검증 오류가 있으면 통합 오류 메시지 설정 및 회원가입 진행 중단
    if (nicknameError != null ||
        emailError != null ||
        passwordError != null ||
        passwordConfirmError != null) {
      state = state.copyWith(
        formErrorMessage: AuthErrorMessages.formValidationFailed,
      );
      return;
    }

    // 2. 닉네임, 이메일 중복 확인
    if (state.nicknameAvailability?.value != true) {
      await _performNicknameAvailabilityCheck();
    }

    if (state.emailAvailability?.value != true) {
      await _performEmailAvailabilityCheck();
    }

    // 중복 확인 결과가 유효하지 않으면 회원가입 진행 중단
    if (state.nicknameAvailability?.value != true ||
        state.emailAvailability?.value != true) {
      state = state.copyWith(
        formErrorMessage: AuthErrorMessages.duplicateCheckRequired,
      );
      return;
    }

    // 3. 회원가입 실행
    state = state.copyWith(
      signupResult: const AsyncValue.loading(),
      formErrorMessage: null, // 🔥 회원가입 시작 시 폼 에러 메시지 클리어
    );

    final signupResult = await _signupUseCase.execute(
      email: state.email,
      password: state.password,
      nickname: state.nickname,
      agreedTermsId: state.agreedTermsId,
    );

    // 🔥 회원가입 성공 시 자동 로그인 수행
    if (signupResult.hasValue) {
      debugPrint('✅ 회원가입 성공, 자동 로그인 시작');

      // 자동 로그인 수행
      final loginResult = await _loginUseCase.execute(
        email: state.email,
        password: state.password,
      );

      if (loginResult.hasValue) {
        debugPrint('✅ 자동 로그인 성공');
        // 로그인 성공 결과를 signupResult에 설정
        state = state.copyWith(signupResult: loginResult);
      } else {
        debugPrint('❌ 자동 로그인 실패: ${loginResult.error}');
        // 자동 로그인 실패 시에도 회원가입은 성공했으므로 성공 처리
        state = state.copyWith(signupResult: signupResult);
      }
    } else {
      // 회원가입 실패
      debugPrint('❌ 회원가입 실패: ${signupResult.error}');
      state = state.copyWith(signupResult: signupResult);
    }
  }

  // 폼 리셋 (회원가입 성공 후 호출)
  void resetForm() {
    state = const SignupState();
  }

  // 약관 동의 ID 설정
  void setAgreedTermsId(String termsId) {
    state = state.copyWith(agreedTermsId: termsId, formErrorMessage: null);
  }

  // 약관 동의 상태 업데이트
  void updateTermsAgreement({
    required String? agreedTermsId,
    required bool isAgreed,
  }) {
    state = state.copyWith(
      agreedTermsId: agreedTermsId,
      isTermsAgreed: isAgreed,
      termsError: null, // 약관 에러 메시지 초기화 추가
      formErrorMessage: null, // 통합 에러 메시지도 초기화
    );
  }
}
