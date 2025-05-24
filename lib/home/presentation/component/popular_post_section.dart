import 'package:devlink_mobile_app/core/utils/app_logger.dart';
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
        _buildPostList(),
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
                    // 안전한 프로필 이미지 처리
                    _buildSafeProfileImage(post.userProfileImageUrl),
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

Widget _buildSafeProfileImage(String? imageUrl) {
  // URL이 비어있거나 null인 경우 기본 아바타 표시
  if (imageUrl == null || imageUrl.trim().isEmpty) {
    return CircleAvatar(
      radius: 12,
      backgroundColor: AppColorStyles.gray40,
      child: Icon(
        Icons.person,
        size: 16,
        color: AppColorStyles.gray80,
      ),
    );
  }

  final String cleanUrl = imageUrl.trim();

  // 올바른 URL 형식인지 확인
  if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
    return CircleAvatar(
      radius: 12,
      backgroundColor: AppColorStyles.gray40,
      child: Icon(
        Icons.person,
        size: 16,
        color: AppColorStyles.gray80,
      ),
    );
  }

  try {
    final uri = Uri.parse(cleanUrl);
    if (uri.host.isEmpty) {
      return CircleAvatar(
        radius: 12,
        backgroundColor: AppColorStyles.gray40,
        child: Icon(
          Icons.person,
          size: 16,
          color: AppColorStyles.gray80,
        ),
      );
    }
  } catch (e) {
    return CircleAvatar(
      radius: 12,
      backgroundColor: AppColorStyles.gray40,
      child: Icon(
        Icons.person,
        size: 16,
        color: AppColorStyles.gray80,
      ),
    );
  }

  // 정상적인 네트워크 이미지인 경우
  return CircleAvatar(
    radius: 12,
    backgroundColor: AppColorStyles.gray40,
    child: ClipOval(
      child: Image.network(
        cleanUrl,
        width: 24,
        height: 24,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          AppLogger.warning('프로필 이미지 로드 실패: $cleanUrl');
          return Icon(
            Icons.person,
            size: 16,
            color: AppColorStyles.gray80,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 1,
                color: AppColorStyles.gray60,
              ),
            ),
          );
        },
      ),
    ),
  );
}
