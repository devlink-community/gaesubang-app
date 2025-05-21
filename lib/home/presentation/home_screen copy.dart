import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

import 'component/group_section.dart';
import 'component/popular_post_section.dart';
import 'home_action.dart';
import 'home_state.dart';

class HomeScreen extends StatelessWidget {
  final HomeState state;
  final Function(HomeAction) onAction;

  const HomeScreen({super.key, required this.state, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColorStyles.primary80.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.code_rounded,
              color: AppColorStyles.primary80,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
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
          icon: const Icon(Icons.search, size: 26),
          color: Colors.grey[700],
          tooltip: '검색',
          onPressed: () {},
        ),
        IconButton(
          icon: Stack(
            alignment: Alignment.topRight,
            children: [
              const Icon(Icons.notifications_outlined, size: 26),
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
          onPressed: () {},
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

  Widget _buildBody() {
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // 오늘의 할 일 카드
                  _buildTodayToDoCard(),

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
            color: Colors.black.withValues(alpha: 0.05),
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
              _buildStatCard('완료한 과제', '12개', Icons.task_alt_outlined),
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
          color: AppColorStyles.primary80.withValues(alpha: 0.05),
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

  Widget _buildTodayToDoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal.shade600, Colors.teal.shade800],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '오늘의 과제',
                  style: AppTextStyles.body1Regular.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '남은 과제',
                      style: AppTextStyles.body2Regular.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '3개',
                      style: AppTextStyles.heading6Bold.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '완료한 과제',
                      style: AppTextStyles.body2Regular.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '8개',
                      style: AppTextStyles.heading6Bold.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.teal.shade700,
              backgroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('과제 확인하기', style: AppTextStyles.body1Regular),
          ),
        ],
      ),
    );
  }
}
