import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../community/domain/model/post.dart';
import '../../../core/styles/app_color_styles.dart';
import '../../../core/styles/app_text_styles.dart';

class PopularPostSection extends StatelessWidget {
  final AsyncValue<List<Post>> posts;
  final Function(String postId) onTapPost;

  const PopularPostSection({
    super.key,
    required this.posts,
    required this.onTapPost,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(),
        const SizedBox(height: 16),
        _buildPostList(),
      ],
    );
  }

  Widget _buildSectionTitle() {
    return Row(
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
              '인기 게시글',
              style: AppTextStyles.subtitle1Bold.copyWith(fontSize: 18),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColorStyles.primary100.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.trending_up,
                size: 14,
                color: AppColorStyles.primary100,
              ),
              const SizedBox(width: 4),
              Text(
                'HOT',
                style: AppTextStyles.captionRegular.copyWith(
                  color: AppColorStyles.primary100,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostList() {
    return posts.when(
      data: (data) {
        if (data.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children:
              data.asMap().entries.map((entry) {
                final index = entry.key;
                final post = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < data.length - 1 ? 12 : 0,
                  ),
                  child: _buildPostItem(post, index + 1),
                );
              }).toList(),
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildPostItem(Post post, int rank) {
    return InkWell(
      onTap: () => onTapPost(post.id),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 프로필 + 작성자 정보 vs 순위 뱃지
            Row(
              children: [
                // 왼쪽: 프로필 + 작성자
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(post.userProfileImageUrl),
                      backgroundColor: AppColorStyles.gray40,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      post.authorNickname,
                      style: AppTextStyles.captionRegular.copyWith(
                        color: AppColorStyles.gray100,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // 오른쪽: 순위 뱃지
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _getRankColor(rank),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: AppTextStyles.captionRegular.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 제목
            Text(
              post.title,
              style: AppTextStyles.subtitle1Bold.copyWith(
                color: AppColorStyles.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // 내용 미리보기
            if (post.content.isNotEmpty)
              Text(
                post.content,
                style: AppTextStyles.body2Regular.copyWith(
                  color: AppColorStyles.gray100,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 8),

            // 해시태그
            if (post.hashTags.isNotEmpty)
              Text(
                post.hashTags.map((tag) => '#$tag').join(' '),
                style: AppTextStyles.captionRegular.copyWith(
                  color: AppColorStyles.primary80,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 8),

            // 하단: 댓글 및 좋아요 수 (오른쪽 정렬)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.comment_outlined,
                  size: 16,
                  color: AppColorStyles.gray80,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.commentCount}',
                  style: AppTextStyles.captionRegular.copyWith(
                    color: AppColorStyles.gray100,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  post.isLikedByCurrentUser
                      ? Icons.favorite
                      : Icons.favorite_border,
                  size: 16,
                  color:
                      post.isLikedByCurrentUser
                          ? Colors.red
                          : AppColorStyles.gray80,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.likeCount}',
                  style: AppTextStyles.captionRegular.copyWith(
                    color: AppColorStyles.gray100,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // 금색
      case 2:
        return const Color(0xFFC0C0C0); // 은색
      case 3:
        return const Color(0xFFCD7F32); // 동색
      default:
        return AppColorStyles.gray80;
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.trending_up_outlined,
            size: 48,
            color: AppColorStyles.gray60,
          ),
          const SizedBox(height: 12),
          Text(
            '아직 인기 게시글이 없습니다',
            style: AppTextStyles.body1Regular.copyWith(
              color: AppColorStyles.gray80,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 게시글을 작성해서 인기글이 되어보세요!',
            style: AppTextStyles.captionRegular.copyWith(
              color: AppColorStyles.gray60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index < 2 ? 12 : 0),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColorStyles.primary100,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorState(Object error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColorStyles.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColorStyles.error,
          ),
          const SizedBox(height: 12),
          Text(
            '인기 게시글을 불러오는데 실패했습니다',
            style: AppTextStyles.body1Regular.copyWith(
              color: AppColorStyles.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '잠시 후 다시 시도해주세요',
            style: AppTextStyles.captionRegular.copyWith(
              color: AppColorStyles.gray80,
            ),
          ),
        ],
      ),
    );
  }
}
