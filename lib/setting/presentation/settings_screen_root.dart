import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'settings_action.dart';
import 'settings_notifier.dart';
import 'settings_screen.dart';

class SettingsScreenRoot extends ConsumerWidget {
  const SettingsScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsNotifierProvider);
    final notifier = ref.watch(settingsNotifierProvider.notifier);

    // 로그아웃 성공 리스너
    ref.listen(settingsNotifierProvider.select((s) => s.logoutResult), (
      previous,
      next,
    ) {
      if (next.hasValue) {
        context.go('/'); // 로그인 화면으로 이동
      } else if (next.hasError) {
        _showErrorSnackBar(context, '로그아웃할 수 없습니다.');
      }
    });

    // 회원탈퇴 성공 리스너
    ref.listen(settingsNotifierProvider.select((s) => s.deleteAccountResult), (
      previous,
      next,
    ) {
      if (next.hasValue) {
        context.go('/'); // 로그인 화면으로 이동
      } else if (next.hasError) {
        _showErrorSnackBar(context, '회원 탈퇴에 실패했습니다.');
      }
    });

    return SettingsScreen(
      state: state,
      onAction: (action) {
        switch (action) {
          case OnTapEditProfile():
            context.push('/edit-profile');
          case OnTapChangePassword():
            context.push('/change-password');
          case OnTapPrivacyPolicy():
            context.push('/privacy-policy');
          case OnTapAppInfo():
            context.push('/app-info');
          case OnTapLogout():
            _showLogoutConfirmDialog(context, notifier, action);
          case OnTapDeleteAccount():
            _showDeleteAccountConfirmDialog(context, notifier, action);
        }
      },
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showLogoutConfirmDialog(
    BuildContext context,
    SettingsNotifier notifier,
    SettingsAction action,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('로그아웃 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                notifier.onAction(action);
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountConfirmDialog(
    BuildContext context,
    SettingsNotifier notifier,
    SettingsAction action,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('회원 탈퇴'),
          content: const Text('모든 데이터가 삭제됩니다. 정말 탈퇴하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                notifier.onAction(action);
              },
              child: const Text('확인', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
