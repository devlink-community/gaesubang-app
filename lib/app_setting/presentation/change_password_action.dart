import 'package:freezed_annotation/freezed_annotation.dart';

part 'change_password_action.freezed.dart';

@freezed
class ChangePasswordAction with _$ChangePasswordAction {
  const factory ChangePasswordAction.emailChanged(String email) = EmailChanged;
  const factory ChangePasswordAction.emailFocusChanged(bool hasFocus) =
      EmailFocusChanged;
  const factory ChangePasswordAction.sendResetEmail() = SendResetEmail;
  const factory ChangePasswordAction.navigateBack() = NavigateBack;
}
