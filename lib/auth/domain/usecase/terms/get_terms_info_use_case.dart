// lib/auth/domain/usecase/terms/get_terms_info_use_case.dart
import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_terms_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetTermsInfoUseCase {
  final AuthTermsRepository _repository;

  GetTermsInfoUseCase({required AuthTermsRepository repository})
    : _repository = repository;

  Future<AsyncValue<TermsAgreement?>> execute(String? termsId) async {
    // termsId가 없으면 기본 빈 약관 정보 반환
    if (termsId == null) {
      // 새로운 약관 ID 생성 (실제로는 저장하지 않음)
      final newTermsId = 'terms_${DateTime.now().millisecondsSinceEpoch}';
      return AsyncData(TermsAgreement(id: newTermsId));
    }

    // 기존 약관 정보 조회
    final result = await _repository.getTermsInfo(termsId);

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
