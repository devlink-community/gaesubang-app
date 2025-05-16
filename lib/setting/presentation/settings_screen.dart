// lib/setting/presentation/settings_screen.dart
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/setting/presentation/settings_action.dart';
import 'package:devlink_mobile_app/setting/presentation/settings_state.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsState state;
  final void Function(SettingsAction action) onAction;

  const SettingsScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // 전체 화면을 감싸는 컨테이너에 그라데이션 적용
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColorStyles.primary100.withValues(alpha: 0.3),
            AppColorStyles.primary100.withValues(alpha: 0.05),
            AppColorStyles.primary100.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Scaffold(
        // 스캐폴드 배경 투명하게 설정
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          centerTitle: true,
          title: Text('환경설정', style: AppTextStyles.heading6Bold),
          automaticallyImplyLeading: true,
          elevation: 0,
          backgroundColor: Colors.transparent, // 앱바 배경 투명
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // 카테고리 제목 - 애니메이션 적용
                      FadeTransition(
                        opacity: _fadeInAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(_fadeInAnimation),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: AppColorStyles.primary100,
                                  width: 3,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.only(left: 8),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              '계정 설정',
                              style: AppTextStyles.subtitle1Bold,
                            ),
                          ),
                        ),
                      ),

                      // 계정 섹션 - 페이드인 애니메이션
                      FadeTransition(
                        opacity: _fadeInAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(_fadeInAnimation),
                          child: _buildSettingsCard([
                            _buildSettingItem(
                              title: '프로필 수정',
                              subtitle: '프로필 정보와 설정을 변경합니다',
                              icon: Icons.person_outline,
                              iconColor: AppColorStyles.primary100,
                              onTap:
                                  () => widget.onAction(
                                    const SettingsAction.onTapEditProfile(),
                                  ),
                            ),
                            _buildSettingItem(
                              title: '비밀번호 수정',
                              subtitle: '계정 보안을 위한 비밀번호를 변경합니다',
                              icon: Icons.lock_outline,
                              iconColor: AppColorStyles.primary100,
                              onTap:
                                  () => widget.onAction(
                                    const SettingsAction.onTapChangePassword(),
                                  ),
                            ),
                          ]),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 정보 섹션 제목 - 애니메이션
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity:
                                _animationController.value > 0.3
                                    ? ((_animationController.value - 0.3) / 0.7)
                                    : 0,
                            child: child,
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: AppColorStyles.primary100,
                                width: 3,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.only(left: 8),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            '앱 정보',
                            style: AppTextStyles.subtitle1Bold,
                          ),
                        ),
                      ),

                      // 앱 정보 섹션 - 슬라이드 애니메이션
                      AnimatedBuilder(
                        animation: _slideAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: Opacity(
                              opacity:
                                  _animationController.value > 0.4 ? 1.0 : 0.0,
                              child: child,
                            ),
                          );
                        },
                        child: _buildSettingsCard([
                          _buildSettingItem(
                            title: '개인정보 처리방침',
                            subtitle: '앱의 개인정보 수집 및 처리 방침을 확인합니다',
                            icon: Icons.security_outlined,
                            iconColor: AppColorStyles.info,
                            onTap:
                                () => widget.onAction(
                                  const SettingsAction.onTapPrivacyPolicy(),
                                ),
                          ),
                          _buildSettingItem(
                            title: '앱 사용 오픈 소스',
                            subtitle: '사용된 오픈소스 라이브러리 목록을 확인합니다',
                            icon: Icons.info_outline,
                            iconColor: AppColorStyles.info,
                            onTap:
                                () => widget.onAction(
                                  const SettingsAction.OnTapOpenSourceLicenses(),
                                ),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // 하단 버튼 섹션 - 애니메이션 적용
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _animationController.value > 0.6 ? 1.0 : 0.0,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        offset: const Offset(0, -2),
                        blurRadius: 10,
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 로그아웃 버튼 - 그라데이션 추가
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed:
                              () => widget.onAction(
                                const SettingsAction.onTapLogout(),
                              ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColorStyles.primary100,
                                  AppColorStyles.primary80,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '로그아웃',
                              style: AppTextStyles.button1Medium.copyWith(
                                color: AppColorStyles.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 회원탈퇴 버튼
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
                          ),
                          onPressed:
                              () => widget.onAction(
                                const SettingsAction.onTapDeleteAccount(),
                              ),
                          child: Text(
                            '회원탈퇴',
                            style: AppTextStyles.button1Medium.copyWith(
                              color: AppColorStyles.gray80,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 설정 카드 위젯
  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColorStyles.gray40, width: 0.5),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 65,
                endIndent: 20,
                color: AppColorStyles.gray40.withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }

  // 설정 항목 위젯 - 서브타이틀 추가
  Widget _buildSettingItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    String? subtitle,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // 아이콘 영역 - 서클 배경 추가
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColorStyles.primary100).withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColorStyles.primary100,
                  size: 22,
                ),
              ),

              const SizedBox(width: 16),

              // 텍스트 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.subtitle1Bold.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.captionRegular.copyWith(
                          color: AppColorStyles.gray80,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 화살표 아이콘
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColorStyles.gray60,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
