import 'package:devlink_mobile_app/community/module/util/%08community_tab_type_enum.dart';
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('커뮤니티'),
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
          _buildTabBar(),
          Expanded(
            child:
                _buildPostList() ?? const Center(child: Text('등록된 게시글이 없습니다')),
          ),
        ],
      ),
    ),
  );

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
              (_, i) => PostListItem(
                post: list[i],
                onTap: () => onAction(CommunityListAction.tapPost(list[i].id)),
              ),
        );
    }
    return null;
  }
}
