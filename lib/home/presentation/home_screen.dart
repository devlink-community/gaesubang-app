import 'package:carousel_slider/carousel_slider.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../ai_assistance/presentation/quiz_banner.dart';
import '../../ai_assistance/presentation/study_tip_banner.dart';
import '../../banner/presentation/component/advertisement_banner.dart';
import 'component/group_section.dart';
import 'component/popular_post_section.dart';
import 'home_action.dart';
import 'home_state.dart';

class HomeScreen extends StatefulWidget {
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBannerIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        color: AppColorStyles.primary80,
        backgroundColor: Colors.white,
        strokeWidth: 3,
        displacement: 40,
        edgeOffset: 0,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
          widget.onAction(const HomeAction.refresh());
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildCarouselSection(),
                  const SizedBox(height: 32),
                  _buildContentSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      toolbarHeight: 70,
      title: Row(
        children: [
          SizedBox(
            width: 53,
            height: 53,
            child: Image.asset(
              'assets/images/gaesubang_mascot.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '개수방',
                style: AppTextStyles.subtitle1Bold.copyWith(
                  color: AppColorStyles.textPrimary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            _buildAppBarAction(
              icon: Icons.notifications_none_rounded,
              onPressed:
                  () => widget.onAction(const HomeAction.onTapNotification()),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColorStyles.secondary01,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        _buildAppBarAction(
          icon: Icons.settings_outlined,
          onPressed: () => widget.onAction(const HomeAction.onTapSettings()),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAppBarAction({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        icon: Icon(icon),
        color: AppColorStyles.black,
        iconSize: 24,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              // 프로필 이미지
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColorStyles.primary80,
                      AppColorStyles.primary100,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColorStyles.primary80.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: _buildProfileImage(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '안녕하세요, ',
                          style: AppTextStyles.subtitle1Bold.copyWith(
                            color: AppColorStyles.textPrimary,
                          ),
                        ),
                        Text(
                          '${widget.state.currentMemberName}님',
                          style: AppTextStyles.subtitle1Bold.copyWith(
                            color: AppColorStyles.textPrimary,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '오늘도 목표를 향해 한 걸음 더!',
                      style: AppTextStyles.subtitle1Bold.copyWith(
                        color: AppColorStyles.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatCard(
                title: '총 학습',
                value: widget.state.totalStudyTimeDisplay,
                icon: Icons.schedule_rounded,
                color: AppColorStyles.primary80,
                backgroundColor: AppColorStyles.primary80.withValues(
                  alpha: 0.1,
                ),
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                title: '연속출석',
                value: widget.state.streakDaysDisplay,
                icon: Icons.local_fire_department_rounded,
                color: Colors.orange,
                backgroundColor: Colors.orange.withValues(alpha: 0.1),
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                title: '참여그룹',
                value: widget.state.joinedGroupCountDisplay,
                icon: Icons.people_rounded,
                color: Colors.blue,
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    // 로딩 상태 체크
    if (widget.state.currentMember.isLoading) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
      );
    }

    // 에러 상태 체크
    if (widget.state.currentMember.hasError) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 30,
          ),
        ),
      );
    }

    // 정상 데이터 표시
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        image:
            widget.state.currentMemberImage != null
                ? DecorationImage(
                  image: NetworkImage(widget.state.currentMemberImage!),
                  fit: BoxFit.cover,
                )
                : null,
      ),
      child:
          widget.state.currentMemberImage == null
              ? Center(
                child: Text(
                  widget.state.currentMemberName.isNotEmpty
                      ? widget.state.currentMemberName[0].toUpperCase()
                      : 'U',
                  style: AppTextStyles.heading6Bold.copyWith(
                    color: Colors.white,
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.subtitle1Bold.copyWith(
                color: color,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTextStyles.captionRegular.copyWith(
                color: color.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselSection() {
    final bannerWidgets = [
      const AdvertisementBanner(),
      DailyQuizBanner(
        skills: widget.userSkills,
        key: ValueKey('quiz_banner_${widget.userSkills ?? "default"}'),
      ),
      StudyTipBanner(
        skills: widget.userSkills,
        key: ValueKey('study_tip_banner_${widget.userSkills ?? "default"}'),
      ),
    ];

    return Column(
      children: [
        const SizedBox(height: 24),
        CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: 230,
            viewportFraction: 0.92,
            enlargeCenterPage: true,
            enlargeFactor: 0.15,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOutCubic,
            onPageChanged: (index, reason) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
          ),
          items:
              bannerWidgets.map((banner) {
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: banner,
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 20),
        AnimatedSmoothIndicator(
          activeIndex: _currentBannerIndex,
          count: bannerWidgets.length,
          effect: ExpandingDotsEffect(
            dotHeight: 8,
            dotWidth: 8,
            expansionFactor: 4,
            spacing: 8,
            activeDotColor: AppColorStyles.primary80,
            dotColor: AppColorStyles.gray40,
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _buildSectionHeader(
            title: '내 그룹',
            subtitle: '오늘도 함께 공부해요',
            icon: Icons.groups_rounded,
          ),
          const SizedBox(height: 16),
          GroupSection(
            groups: widget.state.joinedGroups,
            onTapGroup:
                (groupId) => widget.onAction(HomeAction.onTapGroup(groupId)),
          ),
          const SizedBox(height: 40),
          _buildSectionHeader(
            title: '인기 게시글',
            subtitle: '지금 가장 핫한 글',
            icon: Icons.whatshot_rounded,
          ),
          const SizedBox(height: 16),
          PopularPostSection(
            posts: widget.state.popularPosts,
            onTapPost:
                (postId) =>
                    widget.onAction(HomeAction.onTapPopularPost(postId)),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColorStyles.primary80.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColorStyles.primary80,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle1Bold.copyWith(
                    fontSize: 18,
                    color: AppColorStyles.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.captionRegular.copyWith(
                    color: AppColorStyles.gray80,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: AppColorStyles.gray60,
        ),
      ],
    );
  }
}
