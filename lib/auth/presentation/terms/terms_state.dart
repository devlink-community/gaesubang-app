// lib/auth/presentation/terms/terms_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'terms_state.freezed.dart';

@freezed
class TermsState with _$TermsState {
  const TermsState({
    this.isAllAgreed = false,
    this.isServiceTermsAgreed = false,
    this.isPrivacyPolicyAgreed = false,
    this.isMarketingAgreed = false,
    this.errorMessage,
    this.isSubmitting = false,
    this.formErrorMessage,
    this.isCompleted = false, // savedTermsId 대신 완료 여부만 표시
  });

  final bool isAllAgreed;
  final bool isServiceTermsAgreed;
  final bool isPrivacyPolicyAgreed;
  final bool isMarketingAgreed;
  final String? errorMessage;
  final bool isSubmitting;
  final String? formErrorMessage;
  final bool isCompleted; // 약관 동의 완료 여부
}
