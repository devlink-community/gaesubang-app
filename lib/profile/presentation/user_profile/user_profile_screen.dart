// lib/profile/presentation/user_profile/user_profile_screen.dart
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/profile/presentation/user_profile/user_profile_action.dart';
import 'package:devlink_mobile_app/profile/presentation/user_profile/user_profile_state.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../auth/domain/model/user.dart';

class UserProfileScreen extends StatefulWidget {
  final UserProfileState state;
  final Future<void> Function(UserProfileAction) onAction;

  const UserProfileScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  // SingleTickerProviderStateMixin → TickerProviderStateMixin 변경
  late AnimationController _animationController;
  late AnimationController _floatingController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _floatingAnimation;

  bool _isUserActive(User user) {
    // 1. Summary 정보를 활용하여 타이머 활성 상태 확인
    if (user.summary != null) {
      // summary.isTimerActive getter 활용
      if (user.summary!.isTimerActive) {
        return true;
      }

      // lastTimerTimestamp가 있고 최근 10분 이내인 경우
      if (user.summary!.lastTimerTimestamp != null) {
        final timeDiff = DateTime.now().difference(
          user.summary!.lastTimerTimestamp!,
        );
        if (timeDiff.inMinutes < 10) {
          return true;
        }
      }
    }

    // 2. onAir 상태 확인 (기존 코드)
    return user.onAir;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // 누락된 애니메이션들 초기화
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

    _floatingAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingController.dispose(); // 이 부분도 추가해야 합니다!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColorStyles.primary60,
            AppColorStyles.white,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Text(
            '프로필',
            style: AppTextStyles.heading6Bold.copyWith(
              color: AppColorStyles.textPrimary,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColorStyles.textPrimary,
            ),
            iconSize: 26,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: RefreshIndicator(
          color: AppColorStyles.primary100,
          onRefresh: () async {
            await widget.onAction(const UserProfileAction.refreshProfile());
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 영역 (사진, 닉네임, 설명)
                  FadeTransition(
                    opacity: _fadeInAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(_fadeInAnimation),
                      child: _buildProfileCard(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 개발자 정보 카드
                  if (_shouldShowSkillsSection())
                    AnimatedBuilder(
                      animation: _animationController,
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
                      child: _buildSkillsCard(),
                    ),

                  if (_shouldShowSkillsSection()) const SizedBox(height: 20),

                  // 활동 정보 카드
                  AnimatedBuilder(
                    animation: _slideAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Opacity(
                          opacity: _animationController.value > 0.6 ? 1.0 : 0.0,
                          child: child,
                        ),
                      );
                    },
                    child: _buildActivityCard(),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColorStyles.primary100.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColorStyles.gray40, width: 0.5),
      ),
      child: widget.state.userProfile.when(
        data:
            (member) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                children: [
                  // 플로팅 애니메이션이 적용된 프로필 이미지
                  AnimatedBuilder(
                    animation: _floatingAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatingAnimation.value),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColorStyles.primary100.withValues(
                                  alpha: 0.1,
                                ),
                                blurRadius: 20,
                                spreadRadius: 5,
                                offset: Offset(0, _floatingAnimation.value + 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColorStyles.gray40,
                            backgroundImage:
                                member.image.isNotEmpty == true
                                    ? NetworkImage(member.image)
                                    : null,
                            child:
                                member.image.isEmpty != false
                                    ? Icon(
                                      Icons.person,
                                      size: 50,
                                      color: AppColorStyles.gray100,
                                    )
                                    : null,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // 닉네임
                  Text(
                    member.nickname.isNotEmpty ? member.nickname : '사용자',
                    style: AppTextStyles.heading6Bold.copyWith(
                      color: AppColorStyles.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 설명
                  if (member.description.isNotEmpty == true)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColorStyles.gray40.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColorStyles.gray40.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        member.description,
                        style: AppTextStyles.body1Regular.copyWith(
                          color: AppColorStyles.textPrimary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
        // loading과 error 상태는 기존과 동일...
        loading:
            () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
        error:
            (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColorStyles.error,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '프로필 정보를 불러올 수 없습니다',
                      style: AppTextStyles.body1Regular.copyWith(
                        color: AppColorStyles.gray80,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed:
                          () => widget.onAction(
                            const UserProfileAction.refreshProfile(),
                          ),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('다시 시도'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorStyles.primary100,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildSkillsCard() {
    final member = widget.state.userProfile.valueOrNull;
    if (!_shouldShowSkillsSection()) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColorStyles.primary100.withValues(alpha: 0.02),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColorStyles.gray40, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 (클릭 불가능, 화살표 제거)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColorStyles.primary100.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.code,
                    color: AppColorStyles.primary100,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '개발자 정보',
                  style: AppTextStyles.subtitle1Bold.copyWith(
                    color: AppColorStyles.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 항상 표시되는 콘텐츠
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 직무 정보
                if (member?.position?.isNotEmpty == true) ...[
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: AppColorStyles.primary100,
                          width: 3,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '직무',
                      style: AppTextStyles.subtitle1Bold.copyWith(
                        color: AppColorStyles.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColorStyles.primary100.withValues(alpha: 0.15),
                          AppColorStyles.primary80.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      member!.position!,
                      style: AppTextStyles.body1Regular.copyWith(
                        color: AppColorStyles.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (member.skills?.isNotEmpty == true)
                    const SizedBox(height: 20),
                ],

                // 기술 스택
                if (member?.skills?.isNotEmpty == true) ...[
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: AppColorStyles.primary100,
                          width: 3,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '기술 스택',
                      style: AppTextStyles.subtitle1Bold.copyWith(
                        color: AppColorStyles.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSkillTags(member!.skills!),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillTags(String skills) {
    final skillList =
        skills
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    // 다양한 색상 팔레트
    final colorPalettes = [
      {
        'bg': const Color(0xFFE3F2FD),
        'text': const Color(0xFF1976D2),
        'border': const Color(0xFF42A5F5),
      }, // 파란색
      {
        'bg': const Color(0xFFF3E5F5),
        'text': const Color(0xFF9C27B0),
        'border': const Color(0xFFBA68C8),
      }, // 보라색
      {
        'bg': const Color(0xFFFFF3E0),
        'text': const Color(0xFFFF9800),
        'border': const Color(0xFFFFB74D),
      }, // 주황색
      {
        'bg': const Color(0xFFE8F5E9),
        'text': const Color(0xFF43A047),
        'border': const Color(0xFF66BB6A),
      }, // 초록색
      {
        'bg': const Color(0xFFFFEBEE),
        'text': const Color(0xFFE53935),
        'border': const Color(0xFFEF5350),
      }, // 빨간색
      {
        'bg': const Color(0xFFF1F8E9),
        'text': const Color(0xFF689F38),
        'border': const Color(0xFF8BC34A),
      }, // 라임색
      {
        'bg': const Color(0xFFE0F2F1),
        'text': const Color(0xFF00796B),
        'border': const Color(0xFF26A69A),
      }, // 틸색
      {
        'bg': const Color(0xFFE8EAF6),
        'text': const Color(0xFF3F51B5),
        'border': const Color(0xFF5C6BC0),
      }, // 인디고색
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          skillList.asMap().entries.map((entry) {
            final index = entry.key;
            final skill = entry.value;

            // 스킬별로 고정된 색상 할당 (hashCode 사용으로 일관성 유지)
            final colorIndex =
                (skill.hashCode & 0x7FFFFFFF) % colorPalettes.length;
            final colors = colorPalettes[colorIndex];

            return AnimatedContainer(
              duration: Duration(milliseconds: 200 + (index * 50)),
              curve: Curves.easeOutBack,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors['bg'] as Color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (colors['border'] as Color).withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (colors['border'] as Color).withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                skill,
                style: AppTextStyles.captionRegular.copyWith(
                  color: colors['text'] as Color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildActivityCard() {
    final user = widget.state.userProfile.valueOrNull;
    if (user == null) return const SizedBox.shrink();

    // Summary 정보 가져오기
    final summary = user.summary;
    final hasSummary = summary != null;
    final totalSeconds = summary?.allTimeTotalSeconds ?? 0;
    final streakDays = summary?.currentStreakDays ?? 0;

    // 시간 포맷팅
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final timeDisplay =
        hours > 0
            ? (minutes > 0 ? '$hours시간 $minutes분' : '$hours시간')
            : '$minutes분';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColorStyles.primary100.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColorStyles.gray40, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 (클릭 불가능, 화살표 제거)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColorStyles.primary100.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: AppColorStyles.primary100,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '활동 정보',
                  style: AppTextStyles.subtitle1Bold.copyWith(
                    color: AppColorStyles.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 항상 표시되는 콘텐츠
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 집중 시간 정보 (추가)
                if (hasSummary) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColorStyles.primary100.withValues(alpha: 0.15),
                          AppColorStyles.primary80.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: AppColorStyles.primary100,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '총 집중 시간',
                              style: AppTextStyles.body2Regular.copyWith(
                                color: AppColorStyles.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // FittedBox로 자동 크기 조절
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            timeDisplay,
                            style: AppTextStyles.heading6Bold.copyWith(
                              color: AppColorStyles.primary100,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],

                // 연속 학습일 정보
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColorStyles.primary100.withValues(alpha: 0.15),
                        AppColorStyles.primary80.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '연속 학습일',
                            style: AppTextStyles.body2Regular.copyWith(
                              color: AppColorStyles.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$streakDays일',
                        style: AppTextStyles.heading6Bold.copyWith(
                          color: AppColorStyles.primary100,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 기타 정보들
                _buildInfoRow(
                  icon:
                      _isUserActive(user)
                          ? Icons.circle
                          : Icons.nightlight_round,
                  label: '활동 상태',
                  value: _isUserActive(user) ? '활동 중' : '휴식 중',
                  color: _isUserActive(user) ? Colors.green : Colors.grey,
                ),

                const SizedBox(height: 12),

                _buildInfoRow(
                  icon: Icons.group,
                  label: '참여 그룹',
                  value: '${user.joinedGroups.length}개',
                  color: AppColorStyles.primary100,
                ),

                // 도움말 텍스트
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '함께 성장하는 ${user.position}입니다!',
                          style: AppTextStyles.body2Regular.copyWith(
                            color: AppColorStyles.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body2Regular.copyWith(
                color: AppColorStyles.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body2Regular.copyWith(
              color: AppColorStyles.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowSkillsSection() {
    final member = widget.state.userProfile.valueOrNull;
    return (member?.position?.isNotEmpty == true) ||
        (member?.skills?.isNotEmpty == true);
  }
}
