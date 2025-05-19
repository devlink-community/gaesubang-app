// lib/auth/domain/model/auth_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'member.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.authenticated(Member user) = Authenticated;
  const factory AuthState.unauthenticated() = Unauthenticated;
  const factory AuthState.loading() = Loading;
}
