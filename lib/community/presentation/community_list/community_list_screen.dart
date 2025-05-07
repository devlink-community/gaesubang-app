import 'package:devlink_mobile_app/community/module/util/community_tab_type_enum.dart';
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'community_list_state.dart';
import 'community_list_action.dart';
import '../component/post_list_item.dart';

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
          title: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton(
                        initialValue: state.currentTab,
                        icon: const Icon(Icons.filter_alt_outlined),
                        itemBuilder: (context) {
                          return [
                            PopupMenuItem(
                              child: Text('인기순'),
                              onTap:
                                  () => onAction(
                                    const CommunityListAction.changeTab(
                                      CommunityTabType.popular,
                                    ),
                                  ),
                            ),
                            PopupMenuItem(
                              child: Text('최신순'),
                              onTap:
                                  () => onAction(
                                    const CommunityListAction.changeTab(
                                      CommunityTabType.newest,
                                    ),
                                  ),
                            ),
                          ];
                        },
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Center(
                          child: Text(
                            state.currentTab.name == 'popular' ? '인기순' : '최신순',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(alignment: Alignment.center, child: const Text('게시글 목록')),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed:
                      () => onAction(const CommunityListAction.tapSearch()),
                ),
              ),
            ],
          ),
          actions: [],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => onAction(const CommunityListAction.tapWrite()),
          child: const Icon(Icons.edit),
        ),
        body: RefreshIndicator(
          onRefresh: () async => onAction(const CommunityListAction.refresh()),
          child: Column(
            children: [
              // _buildTabBar(),
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

  Widget _buildTabBar() => TabBar(
    labelColor: Colors.blue,
    indicatorColor: Colors.blue,
    unselectedLabelColor: Colors.grey,
    onTap:
        (i) => onAction(
          CommunityListAction.changeTab(
            i == 0 ? CommunityTabType.popular : CommunityTabType.newest,
          ),
        ),
    tabs: const [Tab(text: '인기순'), Tab(text: '최신순')],
  );

  Widget? _buildPostList() {
    switch (state.postList) {
      case AsyncLoading():
        return const Center(child: CircularProgressIndicator());
      case AsyncError(:final error):
        return Center(child: Text((error as Failure).message));
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
