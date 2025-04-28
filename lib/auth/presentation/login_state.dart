import 'package:devlink_mobile_app/auth/domain/model/user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'login_state.freezed.dart';

@freezed
class LoginState with _$LoginState {
  const LoginState({this.loginUserResult});

  final AsyncValue<User>? loginUserResult;
}
