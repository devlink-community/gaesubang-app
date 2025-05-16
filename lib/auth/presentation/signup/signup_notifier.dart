// lib/auth/presentation/signup/signup_notifier.dart

import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/check_email_availability_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/check_nickname_availability_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/get_terms_info_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/save_terms_agreement_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/signup_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/validate_email_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/validate_nickname_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/validate_password_confirm_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/validate_password_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/validate_terms_agreement_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_action.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_state.dart';
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
        );

      case EmailChanged(:final email):
      // 사용자 편의성을 위해 입력 중에는 유효성 검사 없이 원래 입력값만 유지
        state = state.copyWith(
          email: email,
          emailError: null, // 사용자가 입력 중이면 에러 메시지 제거
          emailSuccess: null, // 사용자가 입력 중이면 성공 메시지도 제거
        );

      case PasswordChanged(:final password):
        state = state.copyWith(
          password: password,
          passwordError: null, // 사용자가 입력 중이면 에러 메시지 제거
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
        );

      case AgreeToTermsChanged(:final agree):
        state = state.copyWith(
          agreeToTerms: agree,
          termsError: null, // 사용자가 체크하면 에러 메시지 제거
        );

    // 포커스 변경 액션 처리 (필드 유효성 검증)
      case NicknameFocusChanged(:final hasFocus):
        if (!hasFocus && state.nickname.isNotEmpty) {
          // 포커스를 잃을 때만 유효성 검증
          final error = await _validateNicknameUseCase.execute(state.nickname);
          state = state.copyWith(nicknameError: error);

          // 닉네임이 유효하면 중복 확인
          if (error == null) {
            await _performNicknameAvailabilityCheck();
          }
        }

      case EmailFocusChanged(:final hasFocus):
        if (!hasFocus) {
          // 포커스를 잃을 때만 유효성 검증 (빈 값도 검증)
          final error = await _validateEmailUseCase.execute(state.email);
          state = state.copyWith(emailError: error);

          // 이메일이 유효하면 중복 확인, 유효하지 않으면 중복 확인 스킵
          if (error == null && state.email.isNotEmpty) {
            await _performEmailAvailabilityCheck();
          }
        }

      case PasswordFocusChanged(:final hasFocus):
        if (!hasFocus && state.password.isNotEmpty) {
          // 포커스를 잃을 때만 유효성 검증
          final error = await _validatePasswordUseCase.execute(state.password);
          state = state.copyWith(passwordError: error);
        }

      case PasswordConfirmFocusChanged(:final hasFocus):
        if (!hasFocus && state.passwordConfirm.isNotEmpty) {
          // 포커스를 잃을 때만 유효성 검증
          final error = await _validatePasswordConfirmUseCase.execute(
            state.password,
            state.passwordConfirm,
          );
          state = state.copyWith(passwordConfirmError: error);
        }

    // 중복 확인 액션 처리
      case CheckNicknameAvailability():
        await _performNicknameAvailabilityCheck();

      case CheckEmailAvailability():
      // 먼저 이메일 형식 유효성 검사 후 중복 확인
        final error = await _validateEmailUseCase.execute(state.email);
        if (error != null) {
          state = state.copyWith(emailError: error);
        } else {
          await _performEmailAvailabilityCheck();
        }

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

  // 닉네임 중복 확인
  Future<void> _performNicknameAvailabilityCheck() async {
    state = state.copyWith(
      nicknameAvailability: const AsyncValue.loading(),
      nicknameSuccess: null, // 로딩 시작할 때 성공 메시지 초기화
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
      );
    }
  }

  // 이메일 중복 확인
  Future<void> _performEmailAvailabilityCheck() async {
    state = state.copyWith(
      emailAvailability: const AsyncValue.loading(),
      emailSuccess: null, // 로딩 시작할 때 성공 메시지 초기화
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
      );
    } else {
      // 사용 불가능하거나 에러가 발생한 경우
      final errorMessage = result.hasError
          ? '이메일 중복 확인 중 오류가 발생했습니다'
          : '이미 사용 중인 이메일입니다';

      state = state.copyWith(
        emailAvailability: result,
        emailError: errorMessage,
        emailSuccess: null,
      );
    }
  }

  // 회원가입 실행
  Future<void> _performSignup() async {
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
      state.agreeToTerms,
    );

    // 검증 결과 업데이트
    state = state.copyWith(
      nicknameError: nicknameError,
      emailError: emailError,
      passwordError: passwordError,
      passwordConfirmError: passwordConfirmError,
      termsError: termsError,
    );

    // 유효성 검증 오류가 있으면 회원가입 진행 중단
    if (nicknameError != null ||
        emailError != null ||
        passwordError != null ||
        passwordConfirmError != null ||
        termsError != null) {
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
      return;
    }

    // 3. 약관 동의 처리
    // 약관 동의 체크는 했지만 약관 ID가 없는 경우 (약관 페이지 방문 없이 체크한 경우)
    String? termsId = state.agreedTermsId;
    if (state.agreeToTerms && termsId == null) {
      // 약관 ID 생성 및 필수 약관 동의 처리
      final getTermsInfoUseCase = ref.read(getTermsInfoUseCaseProvider);
      final saveTermsAgreementUseCase = ref.read(saveTermsAgreementUseCaseProvider);

      // 새 약관 정보 가져오기
      final termsInfoResult = await getTermsInfoUseCase.execute(null);

      if (termsInfoResult.hasValue && termsInfoResult.value != null) {
        // 새 약관에 동의 표시
        final termsAgreement = TermsAgreement(
          id: termsInfoResult.value!.id,
          isAllAgreed: true,
          isServiceTermsAgreed: true,
          isPrivacyPolicyAgreed: true,
          isMarketingAgreed: true, // 마케팅 동의도 기본으로 포함
          agreedAt: DateTime.now(),
        );

        // 약관 동의 저장
        final saveResult = await saveTermsAgreementUseCase.execute(termsAgreement);

        if (saveResult.hasValue) {
          // 저장된 약관 ID 설정
          termsId = saveResult.value?.id;
          // 상태 업데이트
          state = state.copyWith(agreedTermsId: termsId);
        } else if (saveResult.hasError) {
          // 약관 저장 실패 시 오류 표시
          state = state.copyWith(
            termsError: '약관 동의 정보를 저장할 수 없습니다. 다시 시도해주세요.',
          );
          return;
        }
      } else if (termsInfoResult.hasError) {
        // 약관 정보 로드 실패 시 오류 표시
        state = state.copyWith(
          termsError: '약관 정보를 불러올 수 없습니다. 다시 시도해주세요.',
        );
        return;
      }
    }

    // 4. 회원가입 실행
    state = state.copyWith(signupResult: const AsyncValue.loading());

    // 회원가입 시 이메일은 그대로 전달
    // 소문자 변환은 Repository/DataSource 레벨에서 처리
    final result = await _signupUseCase.execute(
      email: state.email,
      password: state.password,
      nickname: state.nickname,
      agreedTermsId: termsId, // 업데이트된 약관 동의 ID 전달
    );

    state = state.copyWith(signupResult: result);
  }

  // 폼 리셋 (회원가입 성공 후 호출)
  void resetForm() {
    state = const SignupState();
  }

  // 약관 동의 ID 설정
  void setAgreedTermsId(String termsId) {
    state = state.copyWith(agreedTermsId: termsId);
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
    );
  }
}