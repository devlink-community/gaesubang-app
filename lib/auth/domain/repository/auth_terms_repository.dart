// lib/auth/domain/repository/auth_terms_repository.dart
import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/core/result/result.dart';

/// 약관 관리 Repository
abstract interface class AuthTermsRepository {
  /// 약관 동의 정보 저장
  Future<Result<TermsAgreement>> saveTermsAgreement(
    TermsAgreement termsAgreement,
  );

  /// 약관 정보 조회
  Future<Result<TermsAgreement?>> getTermsInfo(String? termsId);
}
