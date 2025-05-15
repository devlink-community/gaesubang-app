import 'package:flutter/material.dart';

import 'component/group_section.dart';
import 'component/notice_section.dart';
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
      appBar: AppBar(
        title: Text(
          'Home',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            color: Theme.of(context).colorScheme.onPrimary,
            onPressed: () => onAction(const HomeAction.onTapSettings()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => onAction(const HomeAction.refresh()),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 공지사항 섹션
              NoticeSection(
                notices: state.notices,
                onTapNotice:
                    (noticeId) => onAction(HomeAction.onTapNotice(noticeId)),
              ),

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
                    (postId) => onAction(HomeAction.onTapPopularPost(postId)),
              ),

              // 하단 여백
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
