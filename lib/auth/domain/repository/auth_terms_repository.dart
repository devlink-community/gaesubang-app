// lib/auth/domain/repository/auth_terms_repository.dart
import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/core/result/result.dart';

/// 약관 관리 Repository
abstract interface class AuthTermsRepository {
  /// 약관 동의 정보를 메모리에 임시 저장
  /// 회원가입 완료 전까지만 유지
  Future<Result<void>> saveTermsToMemory(TermsAgreement termsAgreement);

  /// 메모리에서 약관 동의 정보 조회
  /// 회원가입 시 사용
  Future<Result<TermsAgreement?>> getTermsFromMemory();

  /// 메모리에서 약관 동의 정보 삭제
  /// 회원가입 완료 또는 취소 시 호출
  Future<Result<void>> clearTermsFromMemory();

  /// 약관 정보 조회 (기본 약관 템플릿)
  Future<Result<TermsAgreement>> getDefaultTermsTemplate();
}
