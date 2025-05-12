// lib/community/presentation/community_detail/community_detail_screen.dart

import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_state.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/components/comment_item.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class CommunityDetailScreen extends StatefulWidget {
  const CommunityDetailScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  final CommunityDetailState state;
  final void Function(CommunityDetailAction action) onAction;

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게시글 보기')),
      body: _buildBody(),
      /* ----------- 댓글 입력 ----------- */
      bottomSheet: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: '댓글을 입력하세요',
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  final text = _controller.text.trim();
                  if (text.isNotEmpty) {
                    widget.onAction(CommunityDetailAction.addComment(text));
                    _controller.clear();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (widget.state.post) {
      case AsyncLoading():
        return const Center(child: CircularProgressIndicator());
      case AsyncError(:final error, :final stackTrace):
        return const Center(child: Text('글을 불러올 수 없습니다'));
      case AsyncData(:final value):
        return RefreshIndicator(
          onRefresh:
              () async =>
                  widget.onAction(const CommunityDetailAction.toggleLike()),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              /* ----------- 글 본문 카드 ----------- */
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(radius: 16),
                          const SizedBox(width: 8),
                          Text(
                            value.member.nickname,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const Spacer(),
                          Text(
                            '${value.createdAt.year}-${value.createdAt.month.toString().padLeft(2, '0')}-${value.createdAt.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        value.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(value.content),
                      const SizedBox(height: 16),
                      AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            value.image, // ⬅ 목 이미지
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.grey[700],
                            ),
                            onPressed: () {},
                          ),
                          Text('${_getCommentsCount()}'),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: Icon(
                              Icons.favorite_border,
                              color: Colors.grey[700],
                            ),
                            onPressed:
                                () => widget.onAction(
                                  const CommunityDetailAction.toggleLike(),
                                ),
                          ),
                          Text('${value.like.length}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              /* ----------- 댓글 리스트 ----------- */
              _buildCommentList(),
              const SizedBox(height: 80), // for TextField space
            ],
          ),
        );
    }
    return const SizedBox.shrink(); // 빈 위젯 반환
  }

  Widget _buildCommentList() {
    switch (widget.state.comments) {
      case AsyncLoading():
        return const Center(child: CircularProgressIndicator());
      case AsyncError(:final error, :final stackTrace):
        return const Center(child: Text('댓글을 불러올 수 없습니다'));
      case AsyncData(:final value):
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: value.length,
          separatorBuilder:
              (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
          itemBuilder: (_, i) => CommentItem(comment: value[i]),
        );
    }
    return const SizedBox.shrink(); // 빈 위젯 반환
  }

  int _getCommentsCount() {
    switch (widget.state.comments) {
      case AsyncData(:final value):
        return value.length;
      default:
        return 0;
    }
  }
}
