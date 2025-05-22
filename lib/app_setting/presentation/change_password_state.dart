import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'change_password_state.freezed.dart';

@freezed
class ChangePasswordState with _$ChangePasswordState {
  const ChangePasswordState({
    this.email = '',
    this.emailError,
    this.resetPasswordResult,
    this.successMessage,
    this.formErrorMessage,
  });

  final String email;
  final String? emailError;
  final AsyncValue<void>? resetPasswordResult;
  final String? successMessage;
  final String? formErrorMessage;
}
