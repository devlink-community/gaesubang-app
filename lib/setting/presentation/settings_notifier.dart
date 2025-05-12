import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/usecase/delete_account_usecase.dart';
import '../domain/usecase/logout_usecase.dart';
import '../module/settings_di.dart';
import 'settings_action.dart';
import 'settings_state.dart';

part 'settings_notifier.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  late final LogoutUseCase _logoutUseCase;
  late final DeleteAccountUseCase _deleteAccountUseCase;

  @override
  SettingsState build() {
    _logoutUseCase = ref.watch(logoutUseCaseProvider);
    _deleteAccountUseCase = ref.watch(deleteAccountUseCaseProvider);
    return const SettingsState();
  }

  Future<void> onAction(SettingsAction action) async {
    switch (action) {
      case OnTapLogout():
        await _handleLogout();
      case OnTapDeleteAccount():
        await _handleDeleteAccount();
      // 화면 이동 액션들은 Root에서 처리됨
      case OnTapEditProfile():
      case OnTapChangePassword():
      case OnTapPrivacyPolicy():
      case OnTapAppInfo():
      // URL 열기 액션들도 Root에서 처리됨
      case OpenUrlPrivacyPolicy():
      case OpenUrlAppInfo():
        break;
    }
  }

  Future<void> _handleLogout() async {
    state = state.copyWith(logoutResult: const AsyncLoading());
    final asyncResult = await _logoutUseCase.execute();
    state = state.copyWith(logoutResult: asyncResult);
  }

  Future<void> _handleDeleteAccount() async {
    state = state.copyWith(deleteAccountResult: const AsyncLoading());
    final asyncResult = await _deleteAccountUseCase.execute();
    state = state.copyWith(deleteAccountResult: asyncResult);
  }
}
