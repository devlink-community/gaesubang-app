// lib/auth/presentation/forgot_password/forgot_password_action.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'forgot_password_action.freezed.dart';

@freezed
sealed class ForgotPasswordAction with _$ForgotPasswordAction {
  const factory ForgotPasswordAction.emailChanged(String email) = EmailChanged;
  const factory ForgotPasswordAction.emailFocusChanged(bool hasFocus) = EmailFocusChanged;
  const factory ForgotPasswordAction.sendResetEmail() = SendResetEmail;
  const factory ForgotPasswordAction.navigateToLogin() = NavigateToLogin;
}