import 'package:devlink_mobile_app/community/module/util/community_tab_type_enum.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../components/post_list_item.dart';
import 'community_list_action.dart';
import 'community_list_state.dart';

class CommunityListScreen extends StatelessWidget {
  const CommunityListScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  final CommunityListState state;
  final void Function(CommunityListAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text('와글와글 수다방', style: AppTextStyles.heading6Bold),
        actions: [
          // 필터 드롭다운 (검색 아이콘 옆에 배치)
          _buildFilterDropdown(),

          // 검색 아이콘
          IconButton(
            icon: const Icon(Icons.search),
            color: AppColorStyles.textPrimary,
            onPressed: () => onAction(const CommunityListAction.tapSearch()),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: RefreshIndicator(
          color: AppColorStyles.primary100,
          onRefresh: () async => onAction(const CommunityListAction.refresh()),
          child: _buildBody(),
        ),
      ),
    );
  }

  // 필터 드롭다운 메뉴 - 간소화된 버전
  Widget _buildFilterDropdown() {
    return PopupMenuButton<CommunityTabType>(
      initialValue: state.currentTab,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColorStyles.gray40, width: 0.5),
      ),
      elevation: 3,
      color: Colors.white,
      position: PopupMenuPosition.under,
      onSelected: (CommunityTabType tab) {
        onAction(CommunityListAction.changeTab(tab));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.currentTab == CommunityTabType.newest
                  ? Icons.access_time
                  : Icons.trending_up_rounded,
              size: 16,
              color: AppColorStyles.primary100,
            ),
            const SizedBox(width: 4),
            Text(
              state.currentTab == CommunityTabType.newest ? '최신순' : '인기순',
              style: AppTextStyles.body1Regular.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColorStyles.primary100,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: AppColorStyles.primary100,
            ),
          ],
        ),
      ),
      itemBuilder:
          (context) => [
            // 최신순 메뉴 아이템
            PopupMenuItem<CommunityTabType>(
              value: CommunityTabType.newest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color:
                            state.currentTab == CommunityTabType.newest
                                ? AppColorStyles.primary100
                                : AppColorStyles.gray80,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '최신순',
                        style: AppTextStyles.body1Regular.copyWith(
                          fontWeight:
                              state.currentTab == CommunityTabType.newest
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              state.currentTab == CommunityTabType.newest
                                  ? AppColorStyles.primary100
                                  : AppColorStyles.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (state.currentTab == CommunityTabType.newest)
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColorStyles.primary100,
                      ),
                      child: const Center(
                        child: Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            // 구분선 추가
            const PopupMenuDivider(height: 1),
            // 인기순 메뉴 아이템
            PopupMenuItem<CommunityTabType>(
              value: CommunityTabType.popular,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        size: 16,
                        color:
                            state.currentTab == CommunityTabType.popular
                                ? AppColorStyles.primary100
                                : AppColorStyles.gray80,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '인기순',
                        style: AppTextStyles.body1Regular.copyWith(
                          fontWeight:
                              state.currentTab == CommunityTabType.popular
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              state.currentTab == CommunityTabType.popular
                                  ? AppColorStyles.primary100
                                  : AppColorStyles.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (state.currentTab == CommunityTabType.popular)
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColorStyles.primary100,
                      ),
                      child: const Center(
                        child: Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ],
    );
  }

  Widget _buildBody() {
    return _buildPostList() ?? const Center(child: Text('등록된 게시글이 없습니다'));
  }

  Widget? _buildPostList() {
    switch (state.postList) {
      case AsyncLoading():
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColorStyles.primary100,
            ),
            strokeWidth: 3,
          ),
        );

      case AsyncError(:final error, :final stackTrace):
        return _buildErrorView(error);

      case AsyncData(:final value):
        final list = value.isNotEmpty ? value : [];
        if (list.isEmpty) {
          return _buildEmptyView();
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: list.length,
          itemBuilder: (context, index) {
            // 각 아이템 사이에 미세한 공간 추가
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: PostListItem(
                post: list[index],
                onTap:
                    () => onAction(CommunityListAction.tapPost(list[index].id)),
              ),
            );
          },
        );
    }
    return null;
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 80, color: AppColorStyles.gray60),
          const SizedBox(height: 16),
          Text(
            '아직 게시글이 없습니다',
            style: AppTextStyles.subtitle1Bold.copyWith(
              color: AppColorStyles.gray100,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 게시글을 작성해보세요!',
            style: AppTextStyles.body1Regular.copyWith(
              color: AppColorStyles.gray80,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '아래 중앙 버튼을 눌러 새 게시글을 작성할 수 있습니다',
            style: AppTextStyles.captionRegular.copyWith(
              color: AppColorStyles.primary100,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColorStyles.error,
          ),
          const SizedBox(height: 16),
          Text(
            '게시글을 불러올 수 없습니다',
            style: AppTextStyles.subtitle1Bold,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              style: AppTextStyles.body2Regular.copyWith(
                color: AppColorStyles.gray80,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => onAction(const CommunityListAction.refresh()),
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorStyles.primary100,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
