import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// 임포트 수정
import 'component/summary_chart.dart'; // 새로운 차트 컴포넌트
import 'component/total_summary.dart'; // 새로운 총집중시간 컴포넌트
import 'component/user_info_card.dart';
import 'profile_action.dart';
import 'profile_state.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileState state;
  final Future<void> Function(ProfileAction) onAction;

  const ProfileScreen({super.key, required this.state, required this.onAction});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
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
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Text(
            '프로필',
            style: AppTextStyles.heading6Bold.copyWith(
              color: AppColorStyles.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings_outlined, color: AppColorStyles.gray80),
              iconSize: 26,
              onPressed: () => widget.onAction(const OpenSettings()),
            ),
          ],
        ),
        // 기존 body 유지
        body: RefreshIndicator(
          color: AppColorStyles.primary100,
          onRefresh: () async {
            await widget.onAction(const RefreshProfile());
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 영역 - 페이드인 애니메이션 추가
                  FadeTransition(
                    opacity: _fadeInAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(_fadeInAnimation),
                      child: _buildProfileCard(), // 더 컴팩트한 프로필 카드
                    ),
                  ),

                  const SizedBox(height: 20), // 간격 약간 축소
                  // 통계 섹션 헤더 추가
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
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: AppColorStyles.primary100,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '집중 통계',
                          style: AppTextStyles.subtitle1Bold.copyWith(
                            color: AppColorStyles.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 통계 + 차트 영역
                  AnimatedBuilder(
                    animation: _slideAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Opacity(
                          opacity: _animationController.value > 0.4 ? 1.0 : 0.0,
                          child: child,
                        ),
                      );
                    },
                    child: _buildStatsCard(),
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

  // 프로필 카드 위젯 - 더 컴팩트하게 수정
  Widget _buildProfileCard() {
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
      child: widget.state.userProfile.when(
        data:
            (member) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              child: ProfileInfoCard(user: member, compact: false),
            ),
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
                  ],
                ),
              ),
            ),
      ),
    );
  }

  // 통계 카드 위젯 - Summary 모델 사용하도록 수정
  Widget _buildStatsCard() {
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
      child: widget.state.summary.when(
        // focusStats에서 summary로 변경
        data:
            (summary) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 총시간 정보
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
                    child: Center(
                      child: TotalSummary(summary: summary), // 새로운 컴포넌트 사용
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 차트 제목 개선
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
                      '일주일간 활동',
                      style: AppTextStyles.subtitle1Bold.copyWith(
                        color: AppColorStyles.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 차트 영역 - 새로운 SummaryChart 사용
                  Container(
                    height: 240,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SummaryChart(
                      summary: summary,
                      animate: true,
                      animationDuration: const Duration(milliseconds: 1500),
                    ),
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
                            '토요일과 일요일에 가장 집중력이 높아요!',
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
            ),
        loading:
            () => const SizedBox(
              height: 350,
              child: Center(child: CircularProgressIndicator()),
            ),
        error:
            (_, __) => SizedBox(
              height: 350,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColorStyles.error,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '통계 정보를 불러올 수 없습니다',
                      style: AppTextStyles.body1Regular.copyWith(
                        color: AppColorStyles.gray80,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => widget.onAction(const RefreshProfile()),
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
}
