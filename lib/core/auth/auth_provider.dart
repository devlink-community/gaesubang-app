// lib/core/auth/auth_provider.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/data/mapper/user_mapper.dart';
import '../../auth/domain/model/member.dart';
import '../../auth/module/auth_di.dart';
import 'auth_state.dart';

part 'auth_provider.g.dart';

/// 인증 상태 스트림 Provider
/// 앱 전체에서 실시간 인증 상태 변화를 감지
@riverpod
Stream<AuthState> authState(Ref ref) {
  final authDataSource = ref.watch(authDataSourceProvider);

  return authDataSource.authStateChanges.map((userData) {
    if (userData == null) {
      return const AuthState.unauthenticated();
    }

    final member = userData.toMemberWithCalculatedStats();
    return AuthState.authenticated(member);
  });
}

/// 현재 인증 여부 Provider (편의용)
/// UI에서 간단하게 로그인 상태 확인용
@riverpod
bool isAuthenticated(Ref ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.isAuthenticated,
    loading: () => false,
    error: (_, __) => false,
  );
}

/// 현재 사용자 정보 Provider (편의용)
/// UI에서 사용자 정보가 필요할 때 사용
@riverpod
Member? currentUser(Ref ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.user,
    loading: () => null,
    error: (_, __) => null,
  );
}

/// 인증 상태 동기 확인 Provider
/// 라우터에서 리다이렉트 시 사용 (스트림이 아닌 한 번만 확인)
@riverpod
Future<AuthState> currentAuthState(Ref ref) async {
  final authDataSource = ref.watch(authDataSourceProvider);

  try {
    final userData = await authDataSource.getCurrentAuthState();

    if (userData == null) {
      return const AuthState.unauthenticated();
    }

    final member = userData.toMemberWithCalculatedStats();
    return AuthState.authenticated(member);
  } catch (e) {
    return const AuthState.unauthenticated();
  }
}
