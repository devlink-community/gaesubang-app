// lib/community/presentation/community_list/community_list_screen.dart
import 'package:devlink_mobile_app/community/module/util/community_tab_type_enum.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'community_list_state.dart';
import 'community_list_action.dart';
import '../components/post_list_item.dart';

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
        title: const Text('커뮤니티', style: AppTextStyles.heading6Bold),
        leadingWidth: 120,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: _buildFilterDropdown(), // 드롭다운 필터로 변경
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            color: AppColorStyles.textPrimary,
            onPressed: () => onAction(const CommunityListAction.tapSearch()),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => onAction(const CommunityListAction.tapWrite()),
        backgroundColor: AppColorStyles.primary100,
        elevation: 2,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: RefreshIndicator(
        color: AppColorStyles.primary100,
        onRefresh: () async => onAction(const CommunityListAction.refresh()),
        child: _buildBody(),
      ),
    );
  }

  // 필터 드롭다운 메뉴
  Widget _buildFilterDropdown() {
    return Row(
      children: [
        PopupMenuButton<CommunityTabType>(
          initialValue: state.currentTab,
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (CommunityTabType tab) {
            onAction(CommunityListAction.changeTab(tab));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColorStyles.primary60.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColorStyles.primary60, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.currentTab == CommunityTabType.newest ? '최신순' : '인기순',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColorStyles.primary100,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: AppColorStyles.primary100,
                ),
              ],
            ),
          ),
          itemBuilder:
              (context) => [
                PopupMenuItem<CommunityTabType>(
                  value: CommunityTabType.newest,
                  child: Row(
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
                        style: TextStyle(
                          fontWeight:
                              state.currentTab == CommunityTabType.newest
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                      if (state.currentTab == CommunityTabType.newest)
                        const Spacer()
                      else
                        const SizedBox.shrink(),
                      if (state.currentTab == CommunityTabType.newest)
                        const Icon(
                          Icons.check,
                          size: 16,
                          color: AppColorStyles.primary100,
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                ),
                PopupMenuItem<CommunityTabType>(
                  value: CommunityTabType.popular,
                  child: Row(
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
                        style: TextStyle(
                          fontWeight:
                              state.currentTab == CommunityTabType.popular
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                      if (state.currentTab == CommunityTabType.popular)
                        const Spacer()
                      else
                        const SizedBox.shrink(),
                      if (state.currentTab == CommunityTabType.popular)
                        const Icon(
                          Icons.check,
                          size: 16,
                          color: AppColorStyles.primary100,
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
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
          OutlinedButton.icon(
            onPressed: () => onAction(const CommunityListAction.tapWrite()),
            icon: const Icon(Icons.edit),
            label: const Text('글쓰기'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColorStyles.primary100,
              side: BorderSide(color: AppColorStyles.primary100),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
