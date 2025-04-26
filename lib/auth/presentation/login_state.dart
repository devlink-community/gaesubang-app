import 'package:devlink_mobile_app/auth/domain/model/user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_state.freezed.dart';

@freezed
class LoginState with _$LoginState {
  const LoginState({this.user, this.isLoading = false, this.errorMessage});

  final User? user;
  final bool isLoading;
  final String? errorMessage;
}
