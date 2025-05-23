// lib/auth/presentation/terms/terms_notifier.dart
import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/get_terms_info_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/save_terms_agreement_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/auth/presentation/terms/terms_action.dart';
import 'package:devlink_mobile_app/auth/presentation/terms/terms_state.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'terms_notifier.g.dart';

@riverpod
class TermsNotifier extends _$TermsNotifier {
  late final GetTermsInfoUseCase _getTermsInfoUseCase;
  late final SaveTermsAgreementUseCase _saveTermsAgreementUseCase;

  @override
  TermsState build() {
    AppLogger.authInfo('TermsNotifier 초기화 시작');

    _getTermsInfoUseCase = ref.watch(getTermsInfoUseCaseProvider);
    _saveTermsAgreementUseCase = ref.watch(saveTermsAgreementUseCaseProvider);

    // 앱 시작 시 약관 정보 로드
    _loadTermsInfo();

    AppLogger.authInfo('TermsNotifier 초기화 완료');
    return const TermsState();
  }

  Future<void> _loadTermsInfo() async {
    AppLogger.authInfo('약관 정보 로드 시작');
    final startTime = DateTime.now();

    // termsId가 없는 경우 기본 약관 정보 로드
    final result = await _getTermsInfoUseCase.execute(null);

    final duration = DateTime.now().difference(startTime);
    AppLogger.logPerformance('약관 정보 로드', duration);

    if (result.hasValue && result.value != null) {
      // 약관 정보 로드 성공
      AppLogger.authInfo('약관 정보 로드 성공');
      state = state.copyWith(errorMessage: null, formErrorMessage: null);
    } else if (result.hasError) {
      // 약관 정보 로드 실패
      final error = result.error;
      String errorMessage = AuthErrorMessages.dataLoadFailed;

      if (error is Failure) {
        // 에러 타입에 따른 메시지 설정
        errorMessage = error.message;
      }

      AppLogger.error('약관 정보 로드 실패', error: error);
      AppLogger.logState('약관 로드 실패 상세', {
        'error_type': error.runtimeType.toString(),
        'error_message': errorMessage,
        'duration_ms': duration.inMilliseconds,
      });

      state = state.copyWith(
        errorMessage: errorMessage,
        formErrorMessage: errorMessage, // 통합 오류 메시지에도 설정
      );
    }
  }

  Future<void> onAction(TermsAction action) async {
    AppLogger.debug('약관 액션 처리: ${action.runtimeType}');

    switch (action) {
      case AllAgreedChanged(:final value):
        AppLogger.authInfo('전체 약관 동의 변경: $value');
        _handleAllAgreedChanged(value);
        break;

      case ServiceTermsAgreedChanged(:final value):
        AppLogger.debug('서비스 약관 동의 변경: $value');
        _handleServiceTermsAgreedChanged(value);
        break;

      case PrivacyPolicyAgreedChanged(:final value):
        AppLogger.debug('개인정보 약관 동의 변경: $value');
        _handlePrivacyPolicyAgreedChanged(value);
        break;

      case MarketingAgreedChanged(:final value):
        AppLogger.debug('마케팅 약관 동의 변경: $value');
        _handleMarketingAgreedChanged(value);
        break;

      case ViewTermsDetail(:final termType):
        AppLogger.ui('약관 상세보기 요청: $termType');
        // Root에서 처리할 예정이므로 여기서는 로직 미구현
        break;

      case Submit():
        AppLogger.logBanner('약관 동의 제출 시작');
        await _handleSubmit();
        break;

      case NavigateToSignup():
      case NavigateBack():
        AppLogger.navigation('약관 화면 이동: ${action.runtimeType} (Root에서 처리)');
        // Root에서 처리할 예정이므로 여기서는 로직 미구현
        break;
    }
  }

  void _handleAllAgreedChanged(bool value) {
    AppLogger.logState('전체 약관 동의 상태 변경', {
      'all_agreed': value,
      'previous_service': state.isServiceTermsAgreed,
      'previous_privacy': state.isPrivacyPolicyAgreed,
      'previous_marketing': state.isMarketingAgreed,
    });

    state = state.copyWith(
      isAllAgreed: value,
      isServiceTermsAgreed: value,
      isPrivacyPolicyAgreed: value,
      isMarketingAgreed: value,
      errorMessage: null, // 체크 시 에러 메시지 제거
      formErrorMessage: null, // 통합 오류 메시지도 제거
    );

    if (value) {
      AppLogger.authInfo('모든 약관에 동의 완료');
    } else {
      AppLogger.authInfo('모든 약관 동의 해제');
    }
  }

  void _handleServiceTermsAgreedChanged(bool value) {
    final newAllAgreed =
        value && state.isPrivacyPolicyAgreed && state.isMarketingAgreed;

    AppLogger.logState('서비스 약관 동의 상태 변경', {
      'service_agreed': value,
      'privacy_agreed': state.isPrivacyPolicyAgreed,
      'marketing_agreed': state.isMarketingAgreed,
      'new_all_agreed': newAllAgreed,
    });

    state = state.copyWith(
      isServiceTermsAgreed: value,
      // 전체 동의 상태 업데이트
      isAllAgreed: newAllAgreed,
      errorMessage: null, // 체크 시 에러 메시지 제거
      formErrorMessage: null, // 통합 오류 메시지도 제거
    );
  }

  void _handlePrivacyPolicyAgreedChanged(bool value) {
    final newAllAgreed =
        state.isServiceTermsAgreed && value && state.isMarketingAgreed;

    AppLogger.logState('개인정보 약관 동의 상태 변경', {
      'service_agreed': state.isServiceTermsAgreed,
      'privacy_agreed': value,
      'marketing_agreed': state.isMarketingAgreed,
      'new_all_agreed': newAllAgreed,
    });

    state = state.copyWith(
      isPrivacyPolicyAgreed: value,
      // 전체 동의 상태 업데이트
      isAllAgreed: newAllAgreed,
      errorMessage: null, // 체크 시 에러 메시지 제거
      formErrorMessage: null, // 통합 오류 메시지도 제거
    );
  }

  void _handleMarketingAgreedChanged(bool value) {
    final newAllAgreed =
        state.isServiceTermsAgreed && state.isPrivacyPolicyAgreed && value;

    AppLogger.logState('마케팅 약관 동의 상태 변경', {
      'service_agreed': state.isServiceTermsAgreed,
      'privacy_agreed': state.isPrivacyPolicyAgreed,
      'marketing_agreed': value,
      'new_all_agreed': newAllAgreed,
    });

    state = state.copyWith(
      isMarketingAgreed: value,
      // 전체 동의 상태 업데이트
      isAllAgreed: newAllAgreed,
      errorMessage: null, // 체크 시 에러 메시지 제거
      formErrorMessage: null, // 통합 오류 메시지도 제거
    );
  }

  Future<void> _handleSubmit() async {
    final startTime = DateTime.now();
    AppLogger.logStep(1, 4, '약관 동의 제출 처리 시작');

    AppLogger.logState('약관 동의 현재 상태', {
      'all_agreed': state.isAllAgreed,
      'service_agreed': state.isServiceTermsAgreed,
      'privacy_agreed': state.isPrivacyPolicyAgreed,
      'marketing_agreed': state.isMarketingAgreed,
    });

    AppLogger.logStep(2, 4, '필수 약관 동의 확인');
    // 필수 약관 체크 확인
    if (!state.isServiceTermsAgreed || !state.isPrivacyPolicyAgreed) {
      AppLogger.warning('필수 약관 미동의 - 제출 중단');
      AppLogger.logState('필수 약관 동의 상태', {
        'service_agreed': state.isServiceTermsAgreed,
        'privacy_agreed': state.isPrivacyPolicyAgreed,
        'both_required': true,
      });

      state = state.copyWith(
        errorMessage: AuthErrorMessages.termsRequired,
        formErrorMessage: AuthErrorMessages.termsNotAgreed, // 더 상세한 메시지로 설정
      );
      return;
    }

    AppLogger.logStep(3, 4, '약관 동의 정보 저장 시작');
    // 에러 메시지 초기화 및 제출 시작 상태 설정
    state = state.copyWith(
      errorMessage: null,
      formErrorMessage: null, // 통합 오류 메시지도 초기화
      isSubmitting: true,
    );

    // 약관 동의 정보 저장
    final termsAgreementId = DateTime.now().millisecondsSinceEpoch.toString();
    final termsAgreement = TermsAgreement(
      id: termsAgreementId, // 고유 ID 생성
      isAllAgreed: state.isAllAgreed,
      isServiceTermsAgreed: state.isServiceTermsAgreed,
      isPrivacyPolicyAgreed: state.isPrivacyPolicyAgreed,
      isMarketingAgreed: state.isMarketingAgreed,
      agreedAt: DateTime.now(),
    );

    AppLogger.logState('약관 동의 저장 요청', {
      'agreement_id': termsAgreementId,
      'all_agreed': termsAgreement.isAllAgreed,
      'service_agreed': termsAgreement.isServiceTermsAgreed,
      'privacy_agreed': termsAgreement.isPrivacyPolicyAgreed,
      'marketing_agreed': termsAgreement.isMarketingAgreed,
    });

    final result = await _saveTermsAgreementUseCase.execute(termsAgreement);

    final duration = DateTime.now().difference(startTime);
    AppLogger.logPerformance('약관 동의 제출 처리', duration);

    AppLogger.logStep(4, 4, '약관 동의 저장 결과 처리');
    if (result.hasValue) {
      // 약관 동의 저장 성공
      final savedTermsId = result.value?.id;

      AppLogger.logBox(
        '약관 동의 저장 성공',
        '약관 ID: $savedTermsId\n소요시간: ${duration.inMilliseconds}ms',
      );

      state = state.copyWith(
        isSubmitting: false,
        savedTermsId: savedTermsId,
        errorMessage: null,
        formErrorMessage: null,
      );

      // 여기서는 상태만 업데이트하고, 화면 이동은 Root에서 처리
      AppLogger.authInfo('약관 동의 완료 - Root에서 화면 이동 처리 예정');
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

      AppLogger.error('약관 동의 저장 실패', error: error);
      AppLogger.logState('약관 저장 실패 상세', {
        'error_type': error.runtimeType.toString(),
        'error_message': errorMessage,
        'agreement_id': termsAgreementId,
        'duration_ms': duration.inMilliseconds,
      });

      state = state.copyWith(
        isSubmitting: false,
        errorMessage: errorMessage,
        formErrorMessage: errorMessage, // 통합 오류 메시지에도 설정
      );
    }
  }

  void resetState() {
    AppLogger.debug('약관 상태 리셋');
    state = const TermsState();
  }
}
