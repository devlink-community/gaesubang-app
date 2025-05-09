// lib/auth/presentation/forget_password/forget_password_action.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'forget_password_action.freezed.dart';

@freezed
sealed class ForgetPasswordAction with _$ForgetPasswordAction {
  // 이메일 필드 변경
  const factory ForgetPasswordAction.emailChanged(String email) = EmailChanged;

  // 이메일 포커스 변경 (유효성 검증 트리거)
  const factory ForgetPasswordAction.emailFocusChanged(bool hasFocus) = EmailFocusChanged;

  // 비밀번호 재설정 요청 제출
  const factory ForgetPasswordAction.submit() = Submit;

  // 로그인 화면으로 돌아가기
  const factory ForgetPasswordAction.navigateToLogin() = NavigateToLogin;
}