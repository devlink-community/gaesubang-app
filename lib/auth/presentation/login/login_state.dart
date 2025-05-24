// lib/auth/presentation/login/login_state.dart
import 'package:devlink_mobile_app/auth/domain/model/user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_state.freezed.dart';

@freezed
class LoginState with _$LoginState {
  const LoginState({
    this.loginUserResult,
    this.loginErrorMessage, // 오류 메시지 필드 추가
  });

  final AsyncValue<User>? loginUserResult;
  final String? loginErrorMessage; // 사용자에게 표시할 오류 메시지
}
