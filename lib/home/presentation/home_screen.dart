// lib/home/presentation/home_screen.dart

import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

import '../../ai_assistance/presentation/quiz_banner.dart';
import '../../ai_assistance/presentation/study_tip_banner.dart'; // 추가됨
import 'component/group_section.dart';
import 'component/popular_post_section.dart';
import 'home_action.dart';
import 'home_state.dart';

class HomeScreen extends StatelessWidget {
  final HomeState state;
  final Function(HomeAction) onAction;
  final String? userSkills;

  const HomeScreen({
    super.key,
    required this.state,
    required this.onAction,
    this.userSkills,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context),
      body: _buildBody(userSkills),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: Row(
        children: [
          // 코드 아이콘 대신 로고 이미지 사용
          SizedBox(
            width: 60,
            child: Image.asset(
              'assets/images/gaesubang_mascot.png',
              fit: BoxFit.contain,
            ),
          ),

          Text(
            '개수방',
            style: AppTextStyles.heading6Bold.copyWith(
              color: AppColorStyles.primary80,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Stack(
            alignment: Alignment.topRight,
            children: [
              const Icon(LineIcons.bell, size: 26),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColorStyles.secondary01,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          color: Colors.grey[700],
          tooltip: '알림',
          onPressed: () => onAction(const HomeAction.onTapNotification()),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 26),
          color: Colors.grey[700],
          tooltip: '설정',
          onPressed: () => onAction(const HomeAction.onTapSettings()),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(String? skills) {
    return RefreshIndicator(
      color: AppColorStyles.primary80,
      strokeWidth: 2.5,
      onRefresh: () async => onAction(const HomeAction.refresh()),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),

            // 카드 영역 - 횡스크롤로 변경
            const SizedBox(height: 24),
            // StudyTipBanner와 DailyQuizBanner 렌더링 부분 수정
            SizedBox(
              height: 220, // 카드 높이 고정
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // 학습 팁 배너 - ValueKey로 변경
                    StudyTipBanner(
                      skills: skills,
                      key: skills != null ? ValueKey('study_tip_banner_${skills!}') : const ValueKey('study_tip_banner'),
                    ),

                    const SizedBox(width: 12),

                    // 퀴즈 배너 - ValueKey로 변경
                    DailyQuizBanner(
<<<<<<< HEAD
                      skills: skills,
                      key: skills != null ? ValueKey('quiz_banner_${skills!}') : const ValueKey('quiz_banner'),
=======
                      skills: userSkills,
                      key: ValueKey(
                        userSkills ?? 'default',
                      ), // 스킬 변경시 새로고침을 위한 키 추가, null 방지
>>>>>>> 65e0a3e8 (quiz: banner 수정:)
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // 내 그룹 섹션
                  GroupSection(
                    groups: state.userGroups,
                    onTapGroup:
                        (groupId) => onAction(HomeAction.onTapGroup(groupId)),
                  ),

                  const SizedBox(height: 24),

                  // 인기 게시글 섹션
                  PopularPostSection(
                    posts: state.popularPosts,
                    onTapPost:
                        (postId) =>
                        onAction(HomeAction.onTapPopularPost(postId)),
                  ),

                  // 하단 여백
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('안녕하세요, 개발자님!', style: AppTextStyles.heading6Bold),
          const SizedBox(height: 6),
          Text(
            '오늘도 함께 성장해 봐요',
            style: AppTextStyles.body1Regular.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('학습 시간', '32시간', Icons.timer_outlined),
              const SizedBox(width: 12),
              _buildStatCard('연속 출석일', '12일', Icons.task_alt_outlined),
              const SizedBox(width: 12),
              _buildStatCard('참여 그룹', '3개', Icons.group_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColorStyles.primary80.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColorStyles.primary80, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.captionRegular.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.subtitle1Bold),
          ],
        ),
      ),
    );
  }
}