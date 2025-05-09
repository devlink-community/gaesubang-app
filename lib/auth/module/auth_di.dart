import 'package:devlink_mobile_app/auth/data/data_source/auth_data_source.dart';
import 'package:devlink_mobile_app/auth/data/data_source/mock_auth_data_source.dart';
import 'package:devlink_mobile_app/auth/data/data_source/mock_profile_data_source.dart';
import 'package:devlink_mobile_app/auth/data/data_source/profile_data_source.dart';
import 'package:devlink_mobile_app/auth/data/repository_impl/auth_repository_impl.dart';
import 'package:devlink_mobile_app/auth/domain/repository/auth_repository.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/login_use_case.dart';
import 'package:devlink_mobile_app/auth/domain/usecase/mock_login_user_case.dart';
import 'package:devlink_mobile_app/auth/presentation/login/login_screen_root.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_di.g.dart';

// ---------------- DI 부분 ----------------

// AuthDataSource 의존성 주입
@riverpod
AuthDataSource authDataSource(Ref ref) => MockAuthDataSource();

// ProfileDataSource 의존성 주입
@riverpod
ProfileDataSource profileDataSource(Ref ref) => MockProfileDataSource();

@riverpod
AuthRepository authRepository(Ref ref) => AuthRepositoryImpl(
  authDataSource: ref.watch(authDataSourceProvider),
  profileDataSource: ref.watch(profileDataSourceProvider),
);

@riverpod
LoginUseCase loginUseCase(Ref ref) =>
    LoginUseCase(repository: ref.watch(authRepositoryProvider));

@riverpod
LoginUseCase mockLoginUseCase(Ref ref) {
  return MockLoginUseCase();
}

// ---------------- Route 부분 ----------------
final List<GoRoute> authRoutes = [
  GoRoute(path: '/', builder: (context, state) => const LoginScreenRoot()),

  GoRoute(
    path: '/forget-password',
    builder: (context, state) => const _ForgetPasswordMockScreen(),
  ),
  GoRoute(
    path: '/sign-up',
    builder: (context, state) => const _SignUpMockScreen(),
  ),

  GoRoute(path: '/home', builder: (context, state) => const _HomeMockScreen()),

  // <<< 추가
];

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(initialLocation: '/', routes: [...authRoutes]);
}

// ---------- 목업용 임시 스크린들 ----------
class _ForgetPasswordMockScreen extends StatelessWidget {
  const _ForgetPasswordMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('🔒 Forget Password Screen (Mock)')),
    );
  }
}

class _SignUpMockScreen extends StatelessWidget {
  const _SignUpMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('📝 Sign Up Screen (Mock)')),
    );
  }
}

// ---------- 홈 목업용 임시 스크린 ----------

class _HomeMockScreen extends StatelessWidget {
  const _HomeMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('🏠 Home Screen (Mock)')));
  }
}
