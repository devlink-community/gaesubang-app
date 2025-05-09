// lib/auth/presentation/forgot_password/forgot_password_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'forgot_password_state.freezed.dart';

@freezed
class ForgotPasswordState with _$ForgotPasswordState {
  const ForgotPasswordState({
    this.email = '',
    this.emailError,
    this.resetPasswordResult,
  });

  final String email;
  final String? emailError;
  final AsyncValue<void>? resetPasswordResult;
}