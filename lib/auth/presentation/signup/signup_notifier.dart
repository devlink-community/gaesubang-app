// lib/auth/presentation/signup/signup_notifier.dart

import 'package:devlink_mobile_app/auth/domain/usecase/check_email_availability_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/check_nickname_availability_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/signup_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/validate_email_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/validate_nickname_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/validate_password_confirm_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/validate_password_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/validate_terms_agreement_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/get_terms_info_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/save_terms_agreement_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_action.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_state.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'signup_notifier.g.dart';

@riverpod
class SignupNotifier extends _$SignupNotifier {
  late final SignupUseCase _signupUseCase;
  late final CheckNicknameAvailabilityUseCase _checkNicknameAvailabilityUseCase;
  late final CheckEmailAvailabilityUseCase _checkEmailAvailabilityUseCase;
  late final ValidateNicknameUseCase _validateNicknameUseCase;
  late final ValidateEmailUseCase _validateEmailUseCase;
  late final ValidatePasswordUseCase _validatePasswordUseCase;
  late final ValidatePasswordConfirmUseCase _validatePasswordConfirmUseCase;
  late final ValidateTermsAgreementUseCase _validateTermsAgreementUseCase;
  late final GetTermsInfoUseCase _getTermsInfoUseCase;
  late final SaveTermsAgreementUseCase _saveTermsAgreementUseCase;

  @override
  SignupState build() {
    _signupUseCase = ref.watch(signupUseCaseProvider);
    _checkNicknameAvailabilityUseCase = ref.watch(
      checkNicknameAvailabilityUseCaseProvider,
    );
    _checkEmailAvailabilityUseCase = ref.watch(
      checkEmailAvailabilityUseCaseProvider,
    );
    _validateNicknameUseCase = ref.watch(validateNicknameUseCaseProvider);
    _validateEmailUseCase = ref.watch(validateEmailUseCaseProvider);
    _validatePasswordUseCase = ref.watch(validatePasswordUseCaseProvider);
    _validatePasswordConfirmUseCase = ref.watch(
      validatePasswordConfirmUseCaseProvider,
    );
    _validateTermsAgreementUseCase = ref.watch(
      validateTermsAgreementUseCaseProvider,
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
          nicknameError: null, // 사용자가 입력 중이면 에러 메시지 제거
          nicknameSuccess: null, // 사용자가 입력 중이면 성공 메시지도 제거
          formErrorMessage: null, // 통합 오류 메시지도 제거
        );

      case EmailChanged(:final email):
      // 사용자 편의성을 위해 입력 중에는 원래 입력값 유지
        state = state.copyWith(
          email: email,
          emailError: null, // 사용자가 입력 중이면 에러 메시지 제거
          emailSuccess: null, // 사용자가 입력 중이면 성공 메시지도 제거
          formErrorMessage: null, // 통합 오류 메시지도 제거
        );

      case PasswordChanged(:final password):
        state = state.copyWith(
          password: password,
          passwordError: null, // 사용자가 입력 중이면 에러 메시지 제거
          formErrorMessage: null, // 통합 오류 메시지도 제거
          // 비밀번호가 변경되면 비밀번호 확인 유효성도 다시 검증
          passwordConfirmError:
          state.passwordConfirm.isEmpty
              ? null
              : await _validatePasswordConfirmUseCase.execute(
            password,
            state.passwordConfirm,
          ),
        );

      case PasswordConfirmChanged(:final passwordConfirm):
        state = state.copyWith(
          passwordConfirm: passwordConfirm,
          passwordConfirmError: null, // 사용자가 입력 중이면 에러 메시지 제거
          formErrorMessage: null, // 통합 오류 메시지도 제거
        );

      case AgreeToTermsChanged(:final agree):
        state = state.copyWith(
          agreeToTerms: agree,
          termsError: null, // 사용자가 체크하면 에러 메시지 제거
          formErrorMessage: null, // 통합 오류 메시지도 제거
        );

        // 체크박스가 체크되면 자동으로 약관에 동의 처리
        if (agree) {
          await _autoAgreeToTerms();
        } else {
          // 체크 해제된 경우 약관 동의 상태 초기화
          state = state.copyWith(
            agreedTermsId: null,
            isTermsAgreed: false,
          );
        }

    // 포커스 변경 액션 처리 (필드 유효성 검증)
      case NicknameFocusChanged(:final hasFocus):
        if (!hasFocus && state.nickname.isNotEmpty) {
          // 포커스를 잃을 때만 유효성 검증
          final error = await _validateNicknameUseCase.execute(state.nickname);
          state = state.copyWith(nicknameError: error, formErrorMessage: null);

          // 닉네임이 유효하면 중복 확인
          if (error == null) {
            await _performNicknameAvailabilityCheck();
          }
        }

      case EmailFocusChanged(:final hasFocus):
        if (!hasFocus && state.email.isNotEmpty) {
          // 포커스를 잃을 때만 유효성 검증
          // 이메일 주소는 데이터 저장/조회 시 소문자로 변환되지만
          // 화면 표시는 사용자 입력 그대로 유지
          final error = await _validateEmailUseCase.execute(state.email);
          state = state.copyWith(emailError: error, formErrorMessage: null);

          // 이메일이 유효하면 중복 확인, 형식 오류면 중복 확인 건너뜀
          if (error == null) {
            await _performEmailAvailabilityCheck();
          } else {
            // 형식 오류가 있는 경우 중복 확인 결과 초기화 (오류 상태에서도 빨간색 오류 메시지가 표시되도록)
            state = state.copyWith(
              emailAvailability: null,
              emailSuccess: null,
            );
          }
        }

      case PasswordFocusChanged(:final hasFocus):
        if (!hasFocus && state.password.isNotEmpty) {
          // 포커스를 잃을 때만 유효성 검증
          final error = await _validatePasswordUseCase.execute(state.password);
          state = state.copyWith(passwordError: error, formErrorMessage: null);
        }

      case PasswordConfirmFocusChanged(:final hasFocus):
        if (!hasFocus && state.passwordConfirm.isNotEmpty) {
          // 포커스를 잃을 때만 유효성 검증
          final error = await _validatePasswordConfirmUseCase.execute(
            state.password,
            state.passwordConfirm,
          );
          state = state.copyWith(passwordConfirmError: error, formErrorMessage: null);
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
        final saveResult = await _saveTermsAgreementUseCase.execute(termsAgreement);

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
            formErrorMessage: '약관 동의 처리에 실패했습니다. 직접 약관 화면에서 동의해주세요.',
          );
        }
      }
    } catch (e) {
      debugPrint('약관 자동 동의 오류: $e');
      // 오류 발생 시 체크박스 상태를 원래대로 되돌림
      state = state.copyWith(
        agreeToTerms: false,
        formErrorMessage: '약관 동의 처리 중 오류가 발생했습니다. 직접 약관 화면에서 동의해주세요.',
      );
    }
  }

  // 닉네임 중복 확인
  Future<void> _performNicknameAvailabilityCheck() async {
    state = state.copyWith(
      nicknameAvailability: const AsyncValue.loading(),
      nicknameSuccess: null, // 로딩 시작할 때 성공 메시지 초기화
      formErrorMessage: null, // 통합 오류 메시지도 초기화
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
        nicknameSuccess: '사용 가능한 닉네임입니다',
        formErrorMessage: null,
      );
    } else {
      // 사용 불가능하거나 에러가 발생한 경우
      final errorMessage = result.hasError
          ? '닉네임 중복 확인 중 오류가 발생했습니다'
          : '이미 사용 중인 닉네임입니다';

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
    // 이미 이메일 형식 검증에서 오류가 있으면 중복 확인 스킵
    if (state.emailError != null) {
      return;
    }

    state = state.copyWith(
      emailAvailability: const AsyncValue.loading(),
      emailSuccess: null, // 로딩 시작할 때 성공 메시지 초기화
      formErrorMessage: null, // 통합 오류 메시지도 초기화
    );

    // 데이터 비교를 위해 소문자로 변환하여 중복 체크
    final result = await _checkEmailAvailabilityUseCase.execute(state.email);

    // 결과에 따라 에러 또는 성공 메시지 설정
    if (result.hasValue && result.value == true) {
      // 사용 가능한 경우
      state = state.copyWith(
        emailAvailability: result,
        emailError: null,
        emailSuccess: '사용 가능한 이메일입니다',
        formErrorMessage: null,
      );
    } else if (result.hasValue && result.value == false) {
      // 사용 불가능한 경우 (중복된 이메일)
      state = state.copyWith(
        emailAvailability: result,
        emailError: '이미 사용 중인 이메일입니다',
        emailSuccess: null,
        formErrorMessage: null,
      );
    } else {
      // 오류 발생 시 에러 메시지를 표시하지 않고 결과 초기화
      debugPrint('이메일 중복 확인 중 오류 발생: ${result.error}');

      // 이메일 중복 확인 실패 시 UI에 표시하지 않고 결과만 초기화
      state = state.copyWith(
        emailAvailability: null,
        // emailError는 변경하지 않음 (이미 있는 형식 검증 오류 유지)
        emailSuccess: null,
        formErrorMessage: null,
      );
    }
  }

  // 회원가입 실행
  Future<void> _performSignup() async {
    // 폼 전체 오류 메시지 초기화
    state = state.copyWith(formErrorMessage: null);

    // 1. 모든 필드의 유효성 검증
    final nicknameError = await _validateNicknameUseCase.execute(
      state.nickname,
    );
    final emailError = await _validateEmailUseCase.execute(state.email);
    final passwordError = await _validatePasswordUseCase.execute(
      state.password,
    );
    final passwordConfirmError = await _validatePasswordConfirmUseCase.execute(
      state.password,
      state.passwordConfirm,
    );
    final termsError = await _validateTermsAgreementUseCase.execute(
      state.agreeToTerms || state.isTermsAgreed, // 체크박스 체크 또는 이미 약관 동의한 경우
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
      // 약관 오류만 설정하고 다른 통합 오류 메시지는 설정하지 않음
      return;
    }

    // 유효성 검증 오류가 있으면 통합 오류 메시지 설정 및 회원가입 진행 중단
    if (nicknameError != null ||
        emailError != null ||
        passwordError != null ||
        passwordConfirmError != null) {
      state = state.copyWith(
        formErrorMessage: '입력 정보를 확인해주세요', // 통합 오류 메시지 설정
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
        formErrorMessage: '닉네임 또는 이메일 중복을 확인해주세요', // 통합 오류 메시지 설정
      );
      return;
    }

    // 3. 회원가입 실행
    state = state.copyWith(
      signupResult: const AsyncValue.loading(),
      formErrorMessage: null, // 로딩 시작 시 오류 메시지 초기화
    );

    // 회원가입 시 이메일은 그대로 전달
    // 소문자 변환은 Repository/DataSource 레벨에서 처리
    final result = await _signupUseCase.execute(
      email: state.email,
      password: state.password,
      nickname: state.nickname,
      agreedTermsId: state.agreedTermsId, // 약관 동의 ID 전달
    );

    // 회원가입 결과 처리
    if (result.hasError) {
      final error = result.error;
      String errorMessage = '회원가입에 실패했습니다';

      // 에러 타입에 따른 사용자 친화적 메시지 처리
      if (error is Failure) {
        switch (error.type) {
          case FailureType.validation:
            errorMessage = error.message;
            break;
          case FailureType.network:
            errorMessage = '네트워크 연결을 확인해주세요';
            break;
          case FailureType.timeout:
            errorMessage = '요청 시간이 초과되었습니다. 다시 시도해주세요';
            break;
          default:
            errorMessage = error.message;
        }
      }

      // 디버그 정보 로깅
      debugPrint('회원가입 에러: $error');

      // 오류 메시지와 함께 상태 업데이트
      state = state.copyWith(
        signupResult: result,
        formErrorMessage: errorMessage,
      );
    } else {
      // 성공 시 오류 메시지 제거 및 결과 업데이트
      state = state.copyWith(
        signupResult: result,
        formErrorMessage: null,
      );
    }
  }

  // 폼 리셋 (회원가입 성공 후 호출)
  void resetForm() {
    state = const SignupState();
  }

  // 약관 동의 ID 설정
  void setAgreedTermsId(String termsId) {
    state = state.copyWith(
      agreedTermsId: termsId,
      formErrorMessage: null, // ID 설정 시 오류 메시지 초기화
    );
  }

  // 약관 동의 상태 업데이트
  void updateTermsAgreement({
    required String? agreedTermsId,
    required bool isAgreed,
  }) {
    state = state.copyWith(
      agreedTermsId: agreedTermsId,
      isTermsAgreed: isAgreed,
      agreeToTerms: isAgreed, // 약관 동의 체크박스도 함께 업데이트
      formErrorMessage: null, // 상태 업데이트 시 오류 메시지 초기화
    );
  }
}