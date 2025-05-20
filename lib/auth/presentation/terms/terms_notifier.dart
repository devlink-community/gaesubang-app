// lib/auth/presentation/terms/terms_notifier.dart
import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/get_terms_info_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/save_terms_agreement_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/auth/presentation/terms/terms_action.dart';
import 'package:devlink_mobile_app/auth/presentation/terms/terms_state.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'terms_notifier.g.dart';

@riverpod
class TermsNotifier extends _$TermsNotifier {
  late final GetTermsInfoUseCase _getTermsInfoUseCase;
  late final SaveTermsAgreementUseCase _saveTermsAgreementUseCase;

  @override
  TermsState build() {
    _getTermsInfoUseCase = ref.watch(getTermsInfoUseCaseProvider);
    _saveTermsAgreementUseCase = ref.watch(saveTermsAgreementUseCaseProvider);

    // 앱 시작 시 약관 정보 로드
    _loadTermsInfo();

    return const TermsState();
  }

  Future<void> _loadTermsInfo() async {
    // termsId가 없는 경우 기본 약관 정보 로드
    final result = await _getTermsInfoUseCase.execute(null);

    if (result.hasValue && result.value != null) {
      // 약관 정보 로드 성공
      state = state.copyWith(errorMessage: null, formErrorMessage: null);
    } else if (result.hasError) {
      // 약관 정보 로드 실패
      final error = result.error;
      String errorMessage = AuthErrorMessages.dataLoadFailed;

      if (error is Failure) {
        // 에러 타입에 따른 메시지 설정
        errorMessage = error.message;
      }

      state = state.copyWith(
        errorMessage: errorMessage,
        formErrorMessage: errorMessage, // 통합 오류 메시지에도 설정
      );

      // 디버깅 로그
      debugPrint('약관 정보 로드 에러: $error');
    }
  }

  Future<void> onAction(TermsAction action) async {
    switch (action) {
      case AllAgreedChanged(:final value):
        _handleAllAgreedChanged(value);
        break;

      case ServiceTermsAgreedChanged(:final value):
        _handleServiceTermsAgreedChanged(value);
        break;

      case PrivacyPolicyAgreedChanged(:final value):
        _handlePrivacyPolicyAgreedChanged(value);
        break;

      case MarketingAgreedChanged(:final value):
        _handleMarketingAgreedChanged(value);
        break;

      case ViewTermsDetail(:final termType):
        // Root에서 처리할 예정이므로 여기서는 로직 미구현
        break;

      case Submit():
        await _handleSubmit();
        break;

      case NavigateToSignup():
      case NavigateBack():
        // Root에서 처리할 예정이므로 여기서는 로직 미구현
        break;
    }
  }

  void _handleAllAgreedChanged(bool value) {
    state = state.copyWith(
      isAllAgreed: value,
      isServiceTermsAgreed: value,
      isPrivacyPolicyAgreed: value,
      isMarketingAgreed: value,
      errorMessage: null, // 체크 시 에러 메시지 제거
      formErrorMessage: null, // 통합 오류 메시지도 제거
    );
  }

  void _handleServiceTermsAgreedChanged(bool value) {
    state = state.copyWith(
      isServiceTermsAgreed: value,
      // 전체 동의 상태 업데이트
      isAllAgreed:
          value && state.isPrivacyPolicyAgreed && state.isMarketingAgreed,
      errorMessage: null, // 체크 시 에러 메시지 제거
      formErrorMessage: null, // 통합 오류 메시지도 제거
    );
  }

  void _handlePrivacyPolicyAgreedChanged(bool value) {
    state = state.copyWith(
      isPrivacyPolicyAgreed: value,
      // 전체 동의 상태 업데이트
      isAllAgreed:
          state.isServiceTermsAgreed && value && state.isMarketingAgreed,
      errorMessage: null, // 체크 시 에러 메시지 제거
      formErrorMessage: null, // 통합 오류 메시지도 제거
    );
  }

  void _handleMarketingAgreedChanged(bool value) {
    state = state.copyWith(
      isMarketingAgreed: value,
      // 전체 동의 상태 업데이트
      isAllAgreed:
          state.isServiceTermsAgreed && state.isPrivacyPolicyAgreed && value,
      errorMessage: null, // 체크 시 에러 메시지 제거
      formErrorMessage: null, // 통합 오류 메시지도 제거
    );
  }

  Future<void> _handleSubmit() async {
    // 필수 약관 체크 확인
    if (!state.isServiceTermsAgreed || !state.isPrivacyPolicyAgreed) {
      state = state.copyWith(
        errorMessage: AuthErrorMessages.termsRequired,
        formErrorMessage: AuthErrorMessages.termsNotAgreed, // 더 상세한 메시지로 설정
      );
      return;
    }

    // 에러 메시지 초기화 및 제출 시작 상태 설정
    state = state.copyWith(
      errorMessage: null,
      formErrorMessage: null, // 통합 오류 메시지도 초기화
      isSubmitting: true,
    );

    // 약관 동의 정보 저장
    final termsAgreement = TermsAgreement(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // 고유 ID 생성
      isAllAgreed: state.isAllAgreed,
      isServiceTermsAgreed: state.isServiceTermsAgreed,
      isPrivacyPolicyAgreed: state.isPrivacyPolicyAgreed,
      isMarketingAgreed: state.isMarketingAgreed,
      agreedAt: DateTime.now(),
    );

    final result = await _saveTermsAgreementUseCase.execute(termsAgreement);

    if (result.hasValue) {
      // 약관 동의 저장 성공
      final savedTermsId = result.value?.id;
      state = state.copyWith(
        isSubmitting: false,
        savedTermsId: savedTermsId,
        errorMessage: null,
        formErrorMessage: null,
      );

      // 여기서는 상태만 업데이트하고, 화면 이동은 Root에서 처리
    } else if (result.hasError) {
      // 약관 동의 저장 실패
      final error = result.error;
      String errorMessage = AuthErrorMessages.serverError;

      // 에러 타입에 따른 메시지 설정
      if (error is Failure) {
        switch (error.type) {
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

      // 디버깅 로그
      debugPrint('약관 동의 저장 에러: $error');

      state = state.copyWith(
        isSubmitting: false,
        errorMessage: errorMessage,
        formErrorMessage: errorMessage, // 통합 오류 메시지에도 설정
      );
    }
  }

  void resetState() {
    state = const TermsState();
  }
}
