import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// ← 임포트 추가
import 'component/focus_stats_chart.dart';
import 'component/total_focus.dart';
import 'component/user_intro.dart';
import 'intro_action.dart';
import 'intro_state.dart';

class IntroScreen extends StatelessWidget {
  final IntroState state;
  final Future<void> Function(IntroAction) onAction;

  const IntroScreen({super.key, required this.state, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0, // 그림자 제거하여 현대적인 느낌
        backgroundColor: Colors.white, // 배경색을 흰색으로
        title: Text(
          '프로필',
          style: AppTextStyles.heading6Bold.copyWith(
            color: AppColorStyles.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: AppColorStyles.gray80, // 아이콘 색상 변경
            ),
            iconSize: 26, // 크기 약간 축소
            onPressed: () => onAction(const OpenSettings()),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColorStyles.primary100,
        onRefresh: () async {
          // 당겨서 새로고침 기능 추가
          await onAction(const RefreshIntro());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // 프로필 영역 - 카드 스타일로 개선
                _buildProfileCard(),

                const SizedBox(height: 24),

                // 통계 섹션 헤더 추가
                Row(
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

                const SizedBox(height: 16),

                // 통계 + 차트 영역 - 카드 디자인으로 변경
                _buildStatsCard(),

                // 하단 여백
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 프로필 카드 위젯
  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: state.userProfile.when(
        data:
            (member) => Padding(
              padding: const EdgeInsets.all(16),
              child: ProfileInfo(member: member),
            ),
        loading:
            () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
        error:
            (_, __) => SizedBox(
              height: 120,
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
                      '프로필 정보를 불러올 수 없습니다',
                      style: AppTextStyles.body1Regular.copyWith(
                        color: AppColorStyles.gray80,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  // 통계 카드 위젯
  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: state.focusStats.when(
        data:
            (stats) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 총시간 정보 - 디자인 개선
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorStyles.primary100.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: TotalTimeInfo(totalMinutes: stats.totalMinutes),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 차트 제목 추가
                  Text(
                    '일주일간 활동',
                    style: AppTextStyles.subtitle2Regular.copyWith(
                      color: AppColorStyles.gray100,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 차트 영역
                  SizedBox(
                    height: 240, // 고정 높이 지정
                    child: FocusStatsChart(stats: stats),
                  ),

                  // 도움말 텍스트 추가 (선택사항)
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColorStyles.gray40.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 20,
                          color: AppColorStyles.primary80,
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
              height: 350, // 로딩 시에도 카드 사이즈 유지
              child: Center(child: CircularProgressIndicator()),
            ),
        error:
            (_, __) => SizedBox(
              height: 350, // 에러 시에도 카드 사이즈 유지
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
                      onPressed: () => onAction(const RefreshIntro()),
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
