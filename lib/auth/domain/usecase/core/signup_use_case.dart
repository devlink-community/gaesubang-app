// lib/auth/domain/usecase/core/signup_use_case.dart
import 'package:devlink_mobile_app/auth/domain/model/terms_agreement.dart';
import 'package:devlink_mobile_app/auth/domain/model/user.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_core_repository.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// lib/auth/domain/usecase/core/signup_use_case.dart

class SignupUseCase {
  final AuthCoreRepository _repository;

  SignupUseCase({required AuthCoreRepository repository})
    : _repository = repository;

  Future<AsyncValue<User>> execute({
    required String email,
    required String password,
    required String nickname,
    required TermsAgreement termsAgreement, // 약관 동의 정보 객체로 받음
  }) async {
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

    // 회원가입 실행 - TermsAgreement 객체 전달
    final result = await _repository.signup(
      email: email,
      password: password,
      nickname: nickname,
      termsAgreement: termsAgreement, // 객체 전달
    );

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
