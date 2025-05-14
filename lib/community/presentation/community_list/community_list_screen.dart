import 'package:devlink_mobile_app/community/module/util/community_tab_type_enum.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('게시글 목록'),
          leadingWidth: 120,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PopupMenuButton(
                  initialValue: state.currentTab,
                  icon: const Icon(Icons.filter_alt_outlined),
                  padding: EdgeInsets.zero,
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                        value: CommunityTabType.newest,
                        child: const Text('최신순'),
                        onTap:
                            () => onAction(
                              const CommunityListAction.changeTab(
                                CommunityTabType.newest,
                              ),
                            ),
                      ),
                      PopupMenuItem(
                        value: CommunityTabType.popular,
                        child: const Text('인기순'),
                        onTap:
                            () => onAction(
                              const CommunityListAction.changeTab(
                                CommunityTabType.popular,
                              ),
                            ),
                      ),
                    ];
                  },
                ),
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColorStyles.primary60,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      state.currentTab.name == 'popular' ? '인기순' : '최신순',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => onAction(const CommunityListAction.tapSearch()),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => onAction(const CommunityListAction.tapWrite()),
          child: const Icon(Icons.edit),
        ),
        body: RefreshIndicator(
          onRefresh: () async => onAction(const CommunityListAction.refresh()),
          child: Column(
            children: [
              Expanded(
                child:
                    _buildPostList() ??
                    const Center(child: Text('등록된 게시글이 없습니다')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildPostList() {
    switch (state.postList) {
      case AsyncLoading():
        return const Center(child: CircularProgressIndicator());
      case AsyncError(:final error, :final stackTrace):
        return Center(child: Text('에러가 발생했습니다: $error'));
      case AsyncData(:final value):
        final list = value.isNotEmpty ? value : [];
        if (list.isEmpty) {
          return const Center(child: Text('등록된 게시글이 없습니다'));
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder:
              (context, i) => PostListItem(
                post: list[i],
                onTap: () => onAction(CommunityListAction.tapPost(list[i].id)),
              ),
        );
    }
    return null;
  }
}
