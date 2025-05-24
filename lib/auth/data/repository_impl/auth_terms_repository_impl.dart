// lib/auth/data/repository_impl/auth_terms_repository_impl.dart
import 'package:devlink_mobile_app/auth/data/data_source/auth_data_source.dart';
import 'package:devlink_mobile_app/auth/data/mapper/terms_mapper.dart';
import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_terms_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/core/utils/exception_mappers/auth_exception_mapper.dart';

class AuthTermsRepositoryImpl implements AuthTermsRepository {
  final AuthDataSource _authDataSource;

  AuthTermsRepositoryImpl({
    required AuthDataSource authDataSource,
  }) : _authDataSource = authDataSource;

  @override
  Future<Result<TermsAgreement>> saveTermsAgreement(
    TermsAgreement termsAgreement,
  ) async {
    try {
      // TermsAgreement를 Map으로 변환
      final termsData = termsAgreement.toUserDtoMap();

      final response = await _authDataSource.saveTermsAgreement(termsData);

      // Map을 TermsAgreement로 변환
      final savedTerms = response.toTermsAgreement();
      return Result.success(savedTerms);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }

  @override
  Future<Result<TermsAgreement?>> getTermsInfo(String? termsId) async {
    try {
      if (termsId == null) {
        // 기본 약관 정보 조회
        final response = await _authDataSource.fetchTermsInfo();
        final termsAgreement = response.toTermsAgreement();
        return Result.success(termsAgreement);
      }

      // 특정 약관 정보 조회
      final response = await _authDataSource.getTermsInfo(termsId);
      if (response == null) {
        return const Result.success(null);
      }

      final termsAgreement = response.toTermsAgreement();
      return Result.success(termsAgreement);
    } catch (e, st) {
      return Result.error(AuthExceptionMapper.mapAuthException(e, st));
    }
  }
}
