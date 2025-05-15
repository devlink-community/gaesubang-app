// lib/community/presentation/community_detail/community_detail_screen.dart
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_state.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/components/comment_item.dart';
import 'package:devlink_mobile_app/core/component/error_view.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

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
  bool _isLiked = false;
  bool _isBookmarked = false;

  @override
  void didUpdateWidget(CommunityDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 좋아요 상태 업데이트 (현재 사용자 ID는 'user1'로 가정)
    if (widget.state.post != oldWidget.state.post) {
      final post = widget.state.post.value;
      if (post != null) {
        setState(() {
          _isLiked = post.like.any((like) => like.userId == 'user1');
          // 북마크 상태는 별도로 관리해야 함 (여기서는 로컬 상태로 관리)
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 보기'),
        actions: [
          IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () {
              widget.onAction(const CommunityDetailAction.toggleBookmark());
              setState(() {
                _isBookmarked = !_isBookmarked;
              });
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomSheet: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
            top: 8,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: '댓글을 입력하세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).primaryColor,
                child: IconButton(
                  icon: const Icon(Icons.send, size: 20, color: Colors.white),
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      widget.onAction(CommunityDetailAction.addComment(text));
                      _controller.clear();
                    }
                  },
                ),
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
        return ErrorView(
          error: error,
          onRetry: () => widget.onAction(const CommunityDetailAction.refresh()),
        );
      case AsyncData(:final value):
        return RefreshIndicator(
          onRefresh:
              () async =>
                  widget.onAction(const CommunityDetailAction.refresh()),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              // 명시적으로 Widget 타입 지정
              _buildPostCard(value),
              const SizedBox(height: 16),
              _buildCommentsSection(),
              const SizedBox(height: 80), // 댓글 입력창 공간 확보
            ],
          ),
        );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPostCard(Post post) {
    final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
    final formattedDate = dateFormat.format(post.createdAt);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 명시적으로 Widget 타입 지정
            // 작성자 정보 및 날짜
            Row(
              children: <Widget>[
                // 명시적으로 Widget 타입 지정
                CircleAvatar(
                  backgroundImage: NetworkImage(post.member.image),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // 명시적으로 Widget 타입 지정
                    Text(
                      post.member.nickname,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 제목
            Text(
              post.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // 본문
            Text(post.content, style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 16),

            // 이미지 (있는 경우)
            if (post.imageUrls.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post.imageUrls.first,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 해시태그
            if (post.hashTags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                children:
                    post.hashTags
                        .map<Widget>(
                          (tag) => Chip(
                            // 명시적으로 Widget 타입 변환
                            label: Text(tag),
                            backgroundColor: Colors.blue.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // 좋아요, 댓글 수
            Row(
              children: <Widget>[
                // 명시적으로 Widget 타입 지정
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : null,
                  ),
                  onPressed:
                      () => widget.onAction(
                        const CommunityDetailAction.toggleLike(),
                      ),
                ),
                Text(post.like.length.toString()),
                const SizedBox(width: 16),
                const Icon(Icons.comment_outlined),
                const SizedBox(width: 4),
                Text(_getCommentsCount().toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // 명시적으로 Widget 타입 지정
        Row(
          children: <Widget>[
            // 명시적으로 Widget 타입 지정
            const Text(
              '댓글',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getCommentsCount().toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCommentList(),
      ],
    );
  }

  Widget _buildCommentList() {
    switch (widget.state.comments) {
      case AsyncLoading():
        return const Center(child: CircularProgressIndicator());
      case AsyncError(:final error, :final stackTrace):
        return Center(child: Text('댓글을 불러올 수 없습니다: $error'));
      case AsyncData(:final value):
        if (value.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('아직 댓글이 없습니다. 첫 댓글을 남겨보세요!'),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: value.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, i) => CommentItem(comment: value[i]),
        );
    }
    return const SizedBox.shrink();
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
