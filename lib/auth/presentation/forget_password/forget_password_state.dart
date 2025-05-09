// lib/auth/presentation/forget_password/forget_password_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'forget_password_state.freezed.dart';

@freezed
class ForgetPasswordState with _$ForgetPasswordState {
  const ForgetPasswordState({
    // 이메일 필드 값
    this.email = '',

    // 유효성 검증 에러 메시지
    this.emailError,

    // 비밀번호 재설정 요청 상태
    this.resetPasswordResult,

    // 성공 메시지 (UI에 표시될 성공 알림)
    this.successMessage,
  });

  final String email;
  final String? emailError;
  final AsyncValue<void>? resetPasswordResult;
  final String? successMessage;
}