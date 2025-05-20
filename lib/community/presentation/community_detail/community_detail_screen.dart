// lib/community/presentation/community_detail/community_detail_screen.dart
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_state.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/components/comment_item.dart';
import 'package:devlink_mobile_app/core/component/error_view.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 댓글 제출 핸들러
  void _submitComment() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      // 키보드 닫기
      FocusScope.of(context).unfocus();

      // 댓글 추가 액션 실행
      widget.onAction(CommunityDetailAction.addComment(text));

      // 텍스트 필드 비우기
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('게시글', style: AppTextStyles.heading6Bold),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: AppColorStyles.textPrimary),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
              color:
                  _isBookmarked
                      ? AppColorStyles.primary100
                      : AppColorStyles.gray80,
            ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: AppTextStyles.body1Regular,
                  decoration: InputDecoration(
                    hintText: '댓글을 입력하세요',
                    hintStyle: AppTextStyles.body1Regular.copyWith(
                      color: AppColorStyles.gray60,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColorStyles.gray40.withOpacity(0.3),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 1,
                  // 엔터 키를 눌렀을 때도 댓글 제출
                  onSubmitted: (_) => _submitComment(),
                  // 전송 버튼 아이콘으로 변경
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _submitComment,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: AppColorStyles.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColorStyles.primary100.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
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
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColorStyles.primary100,
            ),
          ),
        );
      case AsyncError(:final error, :final stackTrace):
        return ErrorView(
          error: error,
          onRetry: () => widget.onAction(const CommunityDetailAction.refresh()),
        );
      case AsyncData(:final value):
        return RefreshIndicator(
          color: AppColorStyles.primary100,
          onRefresh:
              () async =>
                  widget.onAction(const CommunityDetailAction.refresh()),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 100), // 댓글 입력창 영역 확보
            children: [
              _buildPostCard(value),
              _buildDivider(),
              _buildCommentsSection(),
            ],
          ),
        );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDivider() {
    return Container(height: 8, color: AppColorStyles.gray40.withOpacity(0.2));
  }

  Widget _buildPostCard(Post post) {
    final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
    final formattedDate = dateFormat.format(post.createdAt);

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 작성자 정보 및 날짜
          Row(
            children: [
              // 프로필 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.network(
                  post.userProfileImageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: 50,
                        height: 50,
                        color: AppColorStyles.gray60,
                        child: Icon(
                          Icons.person,
                          color: AppColorStyles.gray100,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 16),

              // 이름과 날짜
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorNickname,
                      style: AppTextStyles.subtitle1Bold,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: AppTextStyles.captionRegular.copyWith(
                        color: AppColorStyles.gray80,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 제목
          Text(post.title, style: AppTextStyles.heading3Bold),

          const SizedBox(height: 16),

          // 본문
          Text(
            post.content,
            style: AppTextStyles.body1Regular.copyWith(
              height: 1.5, // 줄 간격 조정
            ),
          ),

          const SizedBox(height: 24),

          // 이미지 (있는 경우)
          if (post.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                post.imageUrls.first,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stack) => Container(
                      width: double.infinity,
                      height: 200,
                      color: AppColorStyles.gray40,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColorStyles.gray80,
                          size: 40,
                        ),
                      ),
                    ),
              ),
            ),

          const SizedBox(height: 24),

          // 해시태그
          if (post.hashTags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  post.hashTags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColorStyles.primary60.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '#$tag',
                        style: AppTextStyles.captionRegular.copyWith(
                          color: AppColorStyles.primary100,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
            ),

          const SizedBox(height: 24),

          // 좋아요 및 댓글 수 표시
          Row(
            children: [
              // 좋아요 버튼
              GestureDetector(
                onTap:
                    () => widget.onAction(
                      const CommunityDetailAction.toggleLike(),
                    ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 4.0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : AppColorStyles.gray80,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${post.like.length}',
                        style: AppTextStyles.body1Regular.copyWith(
                          color: AppColorStyles.gray100,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // 댓글 수
              Row(
                children: [
                  Icon(
                    Icons.comment_outlined,
                    color: AppColorStyles.gray80,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getCommentsCount().toString(),
                    style: AppTextStyles.body1Regular.copyWith(
                      color: AppColorStyles.gray100,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 댓글 헤더
          Row(
            children: [
              Text('댓글', style: AppTextStyles.subtitle1Bold),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColorStyles.primary100.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getCommentsCount().toString(),
                  style: AppTextStyles.body2Regular.copyWith(
                    color: AppColorStyles.primary100,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 댓글 목록
          _buildCommentList(),
        ],
      ),
    );
  }

  Widget _buildCommentList() {
    switch (widget.state.comments) {
      case AsyncLoading():
        return SizedBox(
          height: 100,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColorStyles.primary100,
              ),
              strokeWidth: 2,
            ),
          ),
        );

      case AsyncError(:final error, :final stackTrace):
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColorStyles.error,
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  '댓글 로딩 중 오류가 발생했습니다',
                  style: AppTextStyles.body1Regular.copyWith(
                    color: AppColorStyles.error,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap:
                      () => widget.onAction(
                        const CommunityDetailAction.refresh(),
                      ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColorStyles.primary100),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '다시 시도',
                      style: AppTextStyles.button2Regular.copyWith(
                        color: AppColorStyles.primary100,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case AsyncData(:final value):
        if (value.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: AppColorStyles.gray60,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '아직 댓글이 없습니다',
                    style: AppTextStyles.subtitle1Bold.copyWith(
                      color: AppColorStyles.gray80,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '첫 댓글을 작성해보세요!',
                    style: AppTextStyles.body1Regular.copyWith(
                      color: AppColorStyles.gray60,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: value.length,
          separatorBuilder: (_, __) => const Divider(height: 32),
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
