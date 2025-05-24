// lib/auth/domain/usecase/terms/clear_terms_from_memory_use_case.dart
import 'package:devlink_mobile_app/auth/domain/repository/auth_terms_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ClearTermsFromMemoryUseCase {
  final AuthTermsRepository _repository;

  ClearTermsFromMemoryUseCase({required AuthTermsRepository repository})
    : _repository = repository;

  /// 메모리에서 약관 동의 정보를 삭제
  /// 회원가입 완료 또는 취소 시 호출
  Future<AsyncValue<void>> execute() async {
    final result = await _repository.clearTermsFromMemory();

    switch (result) {
      case Success():
        return const AsyncData(null);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
