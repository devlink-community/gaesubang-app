// lib/auth/domain/usecase/terms/get_terms_from_memory_use_case.dart
import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_terms_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetTermsFromMemoryUseCase {
  final AuthTermsRepository _repository;

  GetTermsFromMemoryUseCase({required AuthTermsRepository repository})
    : _repository = repository;

  /// 메모리에서 임시 저장된 약관 동의 정보를 조회
  /// 회원가입 시 사용
  Future<AsyncValue<TermsAgreement?>> execute() async {
    final result = await _repository.getTermsFromMemory();

    switch (result) {
      case Success(data: final termsAgreement):
        return AsyncData(termsAgreement);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
