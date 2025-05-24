// lib/auth/data/repository_impl/auth_terms_repository_impl.dart
import 'package:devlink_mobile_app/auth/data/data_source/auth_data_source.dart';
import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_terms_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/exception_mappers/auth_exception_mapper.dart';

class AuthTermsRepositoryImpl implements AuthTermsRepository {
  final AuthDataSource _authDataSource;

  // 메모리에 임시 저장할 약관 동의 정보
  static TermsAgreement? _temporaryTermsAgreement;

  AuthTermsRepositoryImpl({
    required AuthDataSource authDataSource,
  }) : _authDataSource = authDataSource;

  @override
  Future<Result<void>> saveTermsToMemory(TermsAgreement termsAgreement) async {
    try {
      AppLogger.authInfo('약관 동의 정보를 메모리에 임시 저장');
      _temporaryTermsAgreement = termsAgreement;

      AppLogger.logState('메모리 저장된 약관 정보', {
        'service_agreed': termsAgreement.isServiceTermsAgreed,
        'privacy_agreed': termsAgreement.isPrivacyPolicyAgreed,
        'marketing_agreed': termsAgreement.isMarketingAgreed,
        'agreed_at': termsAgreement.agreedAt?.toIso8601String(),
      });

      return const Result.success(null);
    } catch (e, st) {
      AppLogger.error('약관 메모리 저장 실패', error: e, stackTrace: st);
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<TermsAgreement?>> getTermsFromMemory() async {
    try {
      AppLogger.authInfo('메모리에서 약관 동의 정보 조회');

      if (_temporaryTermsAgreement != null) {
        AppLogger.logState('메모리에서 조회된 약관 정보', {
          'service_agreed': _temporaryTermsAgreement!.isServiceTermsAgreed,
          'privacy_agreed': _temporaryTermsAgreement!.isPrivacyPolicyAgreed,
          'marketing_agreed': _temporaryTermsAgreement!.isMarketingAgreed,
          'has_data': true,
        });
      } else {
        AppLogger.debug('메모리에 저장된 약관 정보 없음');
      }

      return Result.success(_temporaryTermsAgreement);
    } catch (e, st) {
      AppLogger.error('약관 메모리 조회 실패', error: e, stackTrace: st);
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<void>> clearTermsFromMemory() async {
    try {
      AppLogger.authInfo('메모리에서 약관 동의 정보 삭제');
      _temporaryTermsAgreement = null;
      return const Result.success(null);
    } catch (e, st) {
      AppLogger.error('약관 메모리 삭제 실패', error: e, stackTrace: st);
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<TermsAgreement>> getDefaultTermsTemplate() async {
    try {
      AppLogger.debug('기본 약관 템플릿 생성');

      // 기본 약관 템플릿 반환
      const defaultTerms = TermsAgreement(
        isAllAgreed: false,
        isServiceTermsAgreed: false,
        isPrivacyPolicyAgreed: false,
        isMarketingAgreed: false,
      );

      return const Result.success(defaultTerms);
    } catch (e, st) {
      AppLogger.error('기본 약관 템플릿 생성 실패', error: e, stackTrace: st);
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }
}
