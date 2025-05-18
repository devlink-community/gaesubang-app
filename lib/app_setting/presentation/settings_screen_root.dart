// lib/app_setting/presentation/settings_screen_root.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/component/custom_alert_dialog.dart';
import 'settings_action.dart';
import 'settings_notifier.dart';
import 'settings_screen.dart';

class SettingsScreenRoot extends ConsumerWidget {
  const SettingsScreenRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsNotifierProvider);
    final notifier = ref.watch(settingsNotifierProvider.notifier);

    // 화면 진입 시 앱 버전 정보 갱신
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.onAction(const SettingsAction.checkAppVersion());
    });

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
      onAction: (action) async {
        switch (action) {
          case OnTapEditProfile():
            context.push('/edit-profile');
          case OnTapChangePassword():
            // 비밀번호 변경을 위해 비밀번호 찾기 화면으로 이동
            context.push('/forgot-password-2');
          case OnTapPrivacyPolicy():
            // 웹 URL 열기
            await _launchUrl(
              'https://www.termsfeed.com/live/11af57de-4ab7-4032-84b8-559e66e7ceb3/',
            );
          case OnTapOpenSourceLicenses():
            context.push('/open-source-licenses');
          case OnTapLogout():
            _showLogoutConfirmDialog(context, notifier, action);
          case OnTapDeleteAccount():
            _showDeleteAccountConfirmDialog(context, notifier, action);
          case OpenUrlPrivacyPolicy():
            await _launchUrl(
              'https://www.termsfeed.com/live/11af57de-4ab7-4032-84b8-559e66e7ceb3/',
            );
          case OpenUrlAppInfo():
            _showAppStoreDialog(context, state.isUpdateAvailable == true);
          case CheckAppVersion():
            notifier.onAction(action);
        }
      },
    );
  }

  // URL 실행 메서드
  Future<void> _launchUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      // 외부 앱을 사용하는 방식으로 변경
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showLogoutConfirmDialog(
    BuildContext context,
    SettingsNotifier notifier,
    SettingsAction action,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CustomAlertDialog(
          title: "로그아웃",
          message: "정말 로그아웃 하시겠습니까?",
          cancelText: "취소",
          confirmText: "확인",
          onConfirm: () {
            Navigator.pop(dialogContext);
            notifier.onAction(action);
          },
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
        return CustomAlertDialog(
          title: "회원탈퇴",
          message: "정말 회원탈퇴 하시겠습니까?\n데이터는 직접 삭제하셔야 합니다.\n회원정보가 사라집니다.",
          cancelText: "취소",
          confirmText: "확인",
          onConfirm: () {
            Navigator.pop(dialogContext);
            notifier.onAction(action);
          },
        );
      },
    );
  }

  void _showAppStoreDialog(BuildContext context, bool needsUpdate) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CustomAlertDialog(
          title: needsUpdate ? "앱 업데이트" : "앱 스토어",
          message:
              needsUpdate
                  ? "새로운 버전이 출시되었습니다.\n업데이트를 진행하시겠습니까?"
                  : "최신 버전을 사용 중입니다.\n앱 스토어로 이동하시겠습니까?",
          cancelText: "나중에",
          confirmText: needsUpdate ? "지금 업데이트" : "스토어로 이동",
          onConfirm: () {
            Navigator.pop(dialogContext);
            // 플랫폼별 스토어 URL 열기
            _launchAppStore();
          },
        );
      },
    );
  }

  void _launchAppStore() {
    // 플랫폼별 스토어 URL (목업)
    const String androidUrl =
        'https://play.google.com/store/apps/details?id=com.devlink.app';
    const String iosUrl = 'https://apps.apple.com/app/devlink/id123456789';

    // 플랫폼에 따라 적절한 스토어 URL 열기
    if (Platform.isAndroid) {
      _launchUrl(androidUrl);
    } else if (Platform.isIOS) {
      _launchUrl(iosUrl);
    } else {
      debugPrint('지원되지 않는 플랫폼입니다.');
    }
  }
}
