// lib/core/auth/auth_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../auth/domain/model/member.dart';

part 'auth_state.freezed.dart';

/// 앱 전체 인증 상태를 나타내는 모델
/// 모든 도메인에서 참조 가능한 core 레벨 인증 상태
@freezed
sealed class AuthState with _$AuthState {
  /// 인증된 상태 - 사용자 정보 포함
  const factory AuthState.authenticated(Member user) = Authenticated;

  /// 인증되지 않은 상태
  const factory AuthState.unauthenticated() = Unauthenticated;

  /// 로딩 중 상태 (초기 인증 상태 확인 중)
  const factory AuthState.loading() = Loading;
}

/// AuthState 확장 메서드
extension AuthStateExtension on AuthState {
  /// 현재 인증되어 있는지 확인
  bool get isAuthenticated {
    return switch (this) {
      Authenticated() => true,
      _ => false,
    };
  }

  /// 현재 사용자 정보 (인증된 경우만, 안전한 null 반환)
  Member? get user {
    return switch (this) {
      Authenticated(user: final member) => member,
      _ => null,
    };
  }

  /// 로딩 중인지 확인
  bool get isLoading {
    return switch (this) {
      Loading() => true,
      _ => false,
    };
  }
}
