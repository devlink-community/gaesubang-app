// lib/auth/data/mapper/terms_mapper.dart
import '../../domain/model/terms_agreement.dart';

extension TermsAgreementMapper on TermsAgreement {
  /// TermsAgreement를 UserDto에 저장할 Map으로 변환
  Map<String, dynamic> toUserDtoMap() {
    return {
      'agreedTermId': id,
      'isServiceTermsAgreed': isServiceTermsAgreed,
      'isPrivacyPolicyAgreed': isPrivacyPolicyAgreed,
      'isMarketingAgreed': isMarketingAgreed,
      'agreedAt': agreedAt,
    };
  }
}

extension MapToTermsAgreementMapper on Map<String, dynamic> {
  /// Map에서 TermsAgreement로 변환
  TermsAgreement toTermsAgreement() {
    return TermsAgreement(
      id: this['agreedTermId'] as String? ?? '',
      isAllAgreed:
          (this['isServiceTermsAgreed'] == true) &&
          (this['isPrivacyPolicyAgreed'] == true),
      isServiceTermsAgreed: this['isServiceTermsAgreed'] as bool? ?? false,
      isPrivacyPolicyAgreed: this['isPrivacyPolicyAgreed'] as bool? ?? false,
      isMarketingAgreed: this['isMarketingAgreed'] as bool? ?? false,
      agreedAt:
          this['agreedAt'] != null
              ? (this['agreedAt'] as dynamic).toDate()
              : null,
    );
  }
}
