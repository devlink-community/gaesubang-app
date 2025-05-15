// lib/setting/presentation/settings_screen.dart
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/setting/presentation/settings_action.dart';
import 'package:devlink_mobile_app/setting/presentation/settings_state.dart';
import 'package:flutter/material.dart';

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
      appBar: AppBar(
        centerTitle: true,
        title: Text('환경설정', style: AppTextStyles.heading6Bold),
        automaticallyImplyLeading: true,
        elevation: 0, // 그림자 제거로 더 현대적인 느낌
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 카테고리 제목
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 12),
                      child: Text(
                        '계정 설정',
                        style: AppTextStyles.subtitle1Bold.copyWith(
                          color: AppColorStyles.gray80,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    // 계정 섹션
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppColorStyles.gray40,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildSettingItem(
                            title: '프로필 수정',
                            icon: Icons.person_outline,
                            iconColor: AppColorStyles.primary100,
                            onTap:
                                () => onAction(
                                  const SettingsAction.onTapEditProfile(),
                                ),
                          ),

                          _buildSettingItem(
                            title: '비밀번호 수정',
                            icon: Icons.lock_outline,
                            iconColor: AppColorStyles.primary100,
                            onTap:
                                () => onAction(
                                  const SettingsAction.onTapChangePassword(),
                                ),
                          ),
                        ],
                      ),
                    ),

                    // 정보 섹션 제목
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 24,
                        bottom: 12,
                      ),
                      child: Text(
                        '앱 정보',
                        style: AppTextStyles.subtitle1Bold.copyWith(
                          color: AppColorStyles.gray80,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    // 정보 섹션
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppColorStyles.gray40,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildSettingItem(
                            title: '개인정보 처리방침',
                            icon: Icons.security_outlined,
                            iconColor: AppColorStyles.info,
                            onTap:
                                () => onAction(
                                  const SettingsAction.onTapPrivacyPolicy(),
                                ),
                          ),

                          _buildSettingItem(
                            title: '앱 사용 오픈 소스',
                            icon: Icons.info_outline,
                            iconColor: AppColorStyles.info,
                            onTap:
                                () => onAction(
                                  const SettingsAction.onTapAppInfo(),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 버튼 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorStyles.primary100,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: AppTextStyles.button1Medium,
                      ),
                      onPressed:
                          () => onAction(const SettingsAction.onTapLogout()),
                      child: Text(
                        '로그아웃',
                        style: AppTextStyles.button1Medium.copyWith(
                          color: AppColorStyles.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColorStyles.gray80,
                        side: BorderSide(color: AppColorStyles.gray60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: AppTextStyles.button1Medium,
                      ),
                      onPressed:
                          () => onAction(
                            const SettingsAction.onTapDeleteAccount(),
                          ),
                      child: Text('회원탈퇴'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Text(
                  //   '버전 1.0.0',
                  //   style: AppTextStyles.captionRegular.copyWith(
                  //     color: AppColorStyles.gray80,
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 설정 항목 위젯 - 아이콘 추가
  Widget _buildSettingItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppColorStyles.primary100,
        size: 24,
      ),
      title: Text(
        title,
        style: AppTextStyles.subtitle1Medium.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 6.0,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
