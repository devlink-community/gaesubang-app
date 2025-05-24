// lib/auth/domain/usecase/terms/get_terms_info_use_case.dart
import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_terms_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetTermsInfoUseCase {
  final AuthTermsRepository _repository;

  GetTermsInfoUseCase({required AuthTermsRepository repository})
    : _repository = repository;

  /// 메모리에서 약관 정보를 조회하거나 기본 템플릿을 반환
  Future<AsyncValue<TermsAgreement>> execute() async {
    // 먼저 메모리에서 약관 정보 조회 시도
    final memoryResult = await _repository.getTermsFromMemory();

    switch (memoryResult) {
      case Success(data: final termsAgreement):
        if (termsAgreement != null) {
          // 메모리에 저장된 약관 정보가 있으면 반환
          return AsyncData(termsAgreement);
        }

        // 메모리에 없으면 기본 템플릿 반환
        final templateResult = await _repository.getDefaultTermsTemplate();
        switch (templateResult) {
          case Success(data: final template):
            return AsyncData(template);
          case Error(failure: final failure):
            return AsyncError(
              failure,
              failure.stackTrace ?? StackTrace.current,
            );
        }

      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
