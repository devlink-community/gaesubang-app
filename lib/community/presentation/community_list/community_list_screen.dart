// lib/community/presentation/community_list/community_list_screen.dart
import 'package:devlink_mobile_app/community/module/util/community_tab_type_enum.dart';
import 'package:devlink_mobile_app/core/component/gradient_app_bar.dart';
import 'package:devlink_mobile_app/core/component/list_skeleton.dart';
import 'package:devlink_mobile_app/core/component/search_bar_component.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../components/post_list_item.dart';
import 'community_list_action.dart';
import 'community_list_state.dart';

enum CommunityFilter {
  all('전체'),
  newest('최신순'),
  popular('인기순');

  final String label;
  const CommunityFilter(this.label);
}

class CommunityListScreen extends StatefulWidget {
  final CommunityListState state;
  final void Function(CommunityListAction action) onAction;

  const CommunityListScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  State<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends State<CommunityListScreen> {
  CommunityFilter _selectedFilter = CommunityFilter.newest;

  @override
  void initState() {
    super.initState();
    // 상태에 따라 초기 필터 설정
    _updateFilterFromState();
  }

  @override
  void didUpdateWidget(CommunityListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 상태 변경 시 필터 업데이트
    if (oldWidget.state.currentTab != widget.state.currentTab) {
      _updateFilterFromState();
    }
  }

  void _updateFilterFromState() {
    setState(() {
      switch (widget.state.currentTab) {
        case CommunityTabType.newest:
          _selectedFilter = CommunityFilter.newest;
        case CommunityTabType.popular:
          _selectedFilter = CommunityFilter.popular;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          _buildSearchBar(),
          // 스티키 헤더로 필터 바 변경
          SliverPersistentHeader(
            delegate: _StickyFilterBarDelegate(
              minHeight: 70,
              maxHeight: 70,
              child: _buildFilterBar(),
            ),
            pinned: true, // 스크롤 시 고정되도록 설정
          ),
          _buildHeadingText(),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return GradientAppBar(
      topText: '함께 이야기해요 👋',
      mainText: '커뮤니티에서 다양한 의견을 나눠보세요',
      expandedHeight: 120,
    );
  }

  // 트렌디한 검색 바
  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: SearchBarComponent(
          onTap: () => widget.onAction(const CommunityListAction.tapSearch()),
          hintText: '관심 있는 주제를 검색해 보세요',
          icon: Icons.search,
        ),
      ),
    );
  }

  // 필터 바 위젯
  Widget _buildFilterBar() {
    return Container(
      color: Colors.white, // 배경색 유지
      padding: const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 10),
      child: Container(
        height: 50,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColorStyles.gray40.withAlpha(0x26), // 15% 투명도
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children:
              CommunityFilter.values.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                      _applyFilter(filter);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColorStyles.primary100
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: AppColorStyles.primary100.withAlpha(
                                      0x33,
                                    ), // 20% 투명도
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                                : null,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getIconForFilter(filter),
                              size: 16,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppColorStyles.gray80,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              filter.label,
                              style: AppTextStyles.body2Regular.copyWith(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : AppColorStyles.gray80,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  // 필터 아이콘 선택
  IconData _getIconForFilter(CommunityFilter filter) {
    switch (filter) {
      case CommunityFilter.all:
        return Icons.grid_view_rounded;
      case CommunityFilter.newest:
        return Icons.access_time;
      case CommunityFilter.popular:
        return Icons.trending_up_rounded;
    }
  }

  // 필터 적용 로직
  void _applyFilter(CommunityFilter filter) {
    // 필터에 따른 액션 처리
    switch (filter) {
      case CommunityFilter.newest:
        widget.onAction(
          const CommunityListAction.changeTab(CommunityTabType.newest),
        );
      case CommunityFilter.popular:
        widget.onAction(
          const CommunityListAction.changeTab(CommunityTabType.popular),
        );
      case CommunityFilter.all:
        // all은 현재 API에서 지원하지 않으므로 newest로 처리
        widget.onAction(
          const CommunityListAction.changeTab(CommunityTabType.newest),
        );
    }
  }

  // 섹션 제목 텍스트
  Widget _buildHeadingText() {
    String headingText;
    switch (_selectedFilter) {
      case CommunityFilter.all:
        headingText = '전체 게시글';
        break;
      case CommunityFilter.newest:
        headingText = '최신 게시글';
        break;
      case CommunityFilter.popular:
        headingText = '인기 게시글';
        break;
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColorStyles.primary100,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  headingText,
                  style: AppTextStyles.subtitle1Bold.copyWith(fontSize: 18),
                ),
              ],
            ),
            // 글쓰기 버튼 (선택적)
            // TextButton.icon(
            //   onPressed:
            //       () => widget.onAction(const CommunityListAction.tapWrite()),
            //   icon: Icon(
            //     Icons.edit,
            //     size: 16,
            //     color: AppColorStyles.primary100,
            //   ),
            //   label: Text(
            //     '글쓰기',
            //     style: TextStyle(
            //       color: AppColorStyles.primary100,
            //       fontSize: 14,
            //       fontWeight: FontWeight.w500,
            //     ),
            //   ),
            //   style: TextButton.styleFrom(
            //     padding: const EdgeInsets.symmetric(
            //       horizontal: 12,
            //       vertical: 8,
            //     ),
            //     backgroundColor: AppColorStyles.primary100.withOpacity(0.1),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(16),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  // _buildBody 메서드 수정
  Widget _buildBody() {
    switch (widget.state.postList) {
      case AsyncLoading():
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                // 스켈레톤 UI 추가
                const ListSkeleton(itemCount: 5),

                // 하단 로딩 표시
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColorStyles.primary100,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '게시글을 불러오는 중...',
                        style: AppTextStyles.captionRegular.copyWith(
                          color: AppColorStyles.gray100,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case AsyncError(:final error):
        // 기존 에러 화면 유지
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 60,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text('데이터를 불러오지 못했습니다', style: AppTextStyles.subtitle1Bold),
                const SizedBox(height: 8),
                Text(
                  '잠시 후 다시 시도해 주세요',
                  style: AppTextStyles.body1Regular.copyWith(
                    color: AppColorStyles.gray100,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed:
                      () =>
                          widget.onAction(const CommunityListAction.refresh()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorStyles.primary100,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('새로고침'),
                ),
              ],
            ),
          ),
        );

      case AsyncData(:final value):
        if (value.isEmpty) {
          return SliverFillRemaining(child: _buildEmptyView());
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PostListItem(
                  post: value[index],
                  onTap:
                      () => widget.onAction(
                        CommunityListAction.tapPost(value[index].id),
                      ),
                ),
              );
            }, childCount: value.length),
          ),
        );

      default:
        return const SliverFillRemaining(
          child: Center(child: Text('알 수 없는 상태입니다.')),
        );
    }
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColorStyles.primary100.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.article_outlined,
              size: 60,
              color: AppColorStyles.primary100.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text('아직 게시글이 없습니다', style: AppTextStyles.subtitle1Bold),
          const SizedBox(height: 8),
          Text(
            '첫 게시글을 작성해보세요!',
            style: AppTextStyles.body1Regular.copyWith(
              color: AppColorStyles.gray100,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed:
                () => widget.onAction(const CommunityListAction.tapWrite()),
            icon: const Icon(Icons.add),
            label: const Text('게시글 작성하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorStyles.primary100,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// 스티키 헤더 delegate 클래스
class _StickyFilterBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyFilterBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // 스크롤에 따라 배경에 그림자 효과를 추가하여 구분감 향상
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow:
            overlapsContent
                ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(0x0D),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                : [],
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_StickyFilterBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
