import 'package:devlink_mobile_app/auth/domain/usecase/login_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/auth/presentation/login_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_notifier.g.dart';

@Riverpod(keepAlive: false)
class LoginNotifier extends _$LoginNotifier {
  late final LoginUseCase _loginUseCase;

  @override
  LoginState build() {
    _loginUseCase = ref.watch(loginUseCaseProvider);
    return const LoginState(); // 초기값 세팅 (user: null, isLoading: false, errorMessage: null)
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(loginUserResult: const AsyncLoading()); // 로딩 상태로 변경

    try {
      final user = await _loginUseCase.execute(
        email: email,
        password: password,
      );
      state = state.copyWith(
        loginUserResult: AsyncData(user),
      ); // 로그인 성공 시 user 설정
    } catch (error, stackTrace) {
      state = state.copyWith(
        loginUserResult: AsyncError(error, stackTrace),
      ); // 로그인 실패 시 에러 설정
    }
  }

  void logout() {
    state = const LoginState(); // user를 null로 리셋
  }
}
