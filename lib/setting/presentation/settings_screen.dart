import 'package:flutter/material.dart';

import 'settings_action.dart';
import 'settings_state.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsState state;
  final void Function(SettingsAction action) onAction;

  const SettingsScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정'), automaticallyImplyLeading: true),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView(
      children: [
        _buildProfileSection(),
        const Divider(),
        _buildSecuritySection(),
        const Divider(),
        _buildInfoSection(),
        const Divider(),
        _buildAccountSection(),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            '프로필',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('프로필 수정'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onAction(const SettingsAction.onTapEditProfile()),
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            '보안',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('비밀번호 변경'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onAction(const SettingsAction.onTapChangePassword()),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            '정보',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip),
          title: const Text('개인정보 처리방침'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onAction(const SettingsAction.onTapPrivacyPolicy()),
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('앱 정보'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onAction(const SettingsAction.onTapAppInfo()),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            '계정',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.orange),
          title: const Text('로그아웃', style: TextStyle(color: Colors.orange)),
          onTap: () => onAction(const SettingsAction.onTapLogout()),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('회원 탈퇴', style: TextStyle(color: Colors.red)),
          onTap: () => onAction(const SettingsAction.onTapDeleteAccount()),
        ),
      ],
    );
  }
}
