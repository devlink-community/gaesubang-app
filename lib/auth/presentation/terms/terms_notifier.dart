// lib/auth/presentation/terms/terms_notifier.dart
import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/terms/get_terms_info_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/terms/save_terms_agreement_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/auth/presentation/terms/terms_action.dart';
import 'package:devlink_mobile_app/auth/presentation/terms/terms_state.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/messages/auth_error_messages.dart';
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
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

    // 기본 약관 정보 로드
    _loadTermsInfo();

    AppLogger.authInfo('TermsNotifier 초기화 완료');
    return const TermsState();
  }

  Future<void> _loadTermsInfo() async {
    AppLogger.authInfo('약관 정보 로드 시작');

    // 기본 약관 템플릿 로드
    final result = await _getTermsInfoUseCase.execute();

    if (result.hasValue) {
      AppLogger.authInfo('약관 정보 로드 성공');
      state = state.copyWith(errorMessage: null, formErrorMessage: null);
    } else if (result.hasError) {
      final error = result.error;
      String errorMessage = AuthErrorMessages.dataLoadFailed;

      if (error is Failure) {
        errorMessage = error.message;
      }

      AppLogger.error('약관 정보 로드 실패', error: error);
      state = state.copyWith(
        errorMessage: errorMessage,
        formErrorMessage: errorMessage,
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
        // Root에서 처리
        break;

      case Submit():
        AppLogger.logBanner('약관 동의 제출 시작');
        await _handleSubmit();
        break;

      case NavigateToSignup():
      case NavigateBack():
        AppLogger.navigation('약관 화면 이동: ${action.runtimeType} (Root에서 처리)');
        // Root에서 처리
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
      errorMessage: null,
      formErrorMessage: null,
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
      isAllAgreed: newAllAgreed,
      errorMessage: null,
      formErrorMessage: null,
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
      isAllAgreed: newAllAgreed,
      errorMessage: null,
      formErrorMessage: null,
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
      isAllAgreed: newAllAgreed,
      errorMessage: null,
      formErrorMessage: null,
    );
  }

  Future<void> _handleSubmit() async {
    final startTime = TimeFormatter.nowInSeoul();
    AppLogger.logStep(1, 4, '약관 동의 유효성 확인');

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
        formErrorMessage: AuthErrorMessages.termsNotAgreed,
      );
      return;
    }

    AppLogger.logStep(2, 4, '약관 동의 정보 생성');

    // 약관 동의 정보 생성
    final termsAgreement = TermsAgreement(
      isAllAgreed: state.isAllAgreed,
      isServiceTermsAgreed: state.isServiceTermsAgreed,
      isPrivacyPolicyAgreed: state.isPrivacyPolicyAgreed,
      isMarketingAgreed: state.isMarketingAgreed,
      agreedAt: TimeFormatter.nowInSeoul(),
    );

    AppLogger.logState('약관 동의 정보', {
      'all_agreed': termsAgreement.isAllAgreed,
      'service_agreed': termsAgreement.isServiceTermsAgreed,
      'privacy_agreed': termsAgreement.isPrivacyPolicyAgreed,
      'marketing_agreed': termsAgreement.isMarketingAgreed,
      'agreed_at': termsAgreement.agreedAt?.toIso8601String(),
    });

    AppLogger.logStep(3, 4, '약관 동의 메모리 저장');

    // 제출 시작 상태 설정
    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
      formErrorMessage: null,
    );

    // 메모리에만 저장
    final result = await _saveTermsAgreementUseCase.execute(termsAgreement);

    final duration = TimeFormatter.nowInSeoul().difference(startTime);
    AppLogger.logPerformance('약관 동의 처리', duration);

    AppLogger.logStep(4, 4, '약관 동의 저장 결과 처리');

    if (result.hasValue) {
      // 약관 동의 메모리 저장 성공
      AppLogger.logBox(
        '약관 동의 완료',
        '메모리에 임시 저장됨\n소요시간: ${duration.inMilliseconds}ms',
      );

      state = state.copyWith(
        isSubmitting: false,
        isCompleted: true, // 성공 표시용 더미 값
        errorMessage: null,
        formErrorMessage: null,
      );

      // Root에서 화면 이동 처리
      AppLogger.authInfo('약관 동의 완료 - Root에서 화면 이동 처리 예정');
    } else if (result.hasError) {
      // 약관 동의 저장 실패
      final error = result.error;
      String errorMessage = AuthErrorMessages.serverError;

      if (error is Failure) {
        errorMessage = error.message;
      }

      AppLogger.error('약관 동의 저장 실패', error: error);

      state = state.copyWith(
        isSubmitting: false,
        errorMessage: errorMessage,
        formErrorMessage: errorMessage,
      );
    }
  }

  void resetState() {
    AppLogger.debug('약관 상태 리셋');
    state = const TermsState();
  }
}
