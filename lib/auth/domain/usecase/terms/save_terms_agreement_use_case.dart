// lib/auth/domain/usecase/terms/save_terms_agreement_use_case.dart
import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_terms_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SaveTermsAgreementUseCase {
  final AuthTermsRepository _repository;

  SaveTermsAgreementUseCase({required AuthTermsRepository repository})
    : _repository = repository;

  Future<AsyncValue<void>> execute(TermsAgreement termsAgreement) async {
    // 필수 약관 동의 여부 확인
    if (!termsAgreement.isRequiredTermsAgreed) {
      return AsyncError(
        Failure(
          FailureType.validation,
          '필수 약관에 동의해야 합니다',
        ),
        StackTrace.current,
      );
    }

    // 현재 시간으로 동의 시간 설정
    final updatedTerms = TermsAgreement(
      isAllAgreed: termsAgreement.isAllAgreed,
      isServiceTermsAgreed: termsAgreement.isServiceTermsAgreed,
      isPrivacyPolicyAgreed: termsAgreement.isPrivacyPolicyAgreed,
      isMarketingAgreed: termsAgreement.isMarketingAgreed,
      agreedAt: TimeFormatter.nowInSeoul(), // 현재 시간으로 동의 시간 업데이트
    );

    // 메모리에만 저장
    final result = await _repository.saveTermsToMemory(updatedTerms);

    switch (result) {
      case Success():
        return const AsyncData(null);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
