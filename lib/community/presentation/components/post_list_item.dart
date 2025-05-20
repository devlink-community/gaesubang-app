// lib/community/presentation/components/post_list_item.dart
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PostListItem extends StatelessWidget {
  const PostListItem({super.key, required this.post, required this.onTap});

  final Post post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 이미지 URL 결정 (빈 리스트면 기본 이미지 사용)
    final imageUrl =
        post.imageUrls.isNotEmpty
            ? post.imageUrls.first
            : 'https://i.namu.wiki/i/R0AhIJhNi8fkU2Al72pglkrT8QenAaCJd1as-d_iY6MC8nub1iI5VzIqzJlLa-1uzZm--TkB-KHFiT-P-t7bEg.webp';

    // 날짜 포맷터
    final dateFormat = DateFormat('yyyy-MM-dd');
    final formattedDate = dateFormat.format(post.createdAt.toLocal());

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // 투명한 부분까지 터치 감지
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColorStyles.gray40,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColorStyles.primary100,
                      ),
                      strokeWidth: 2,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image,
                    size: 30,
                    color: AppColorStyles.gray60,
                  );
                },
              ),
            ),

            const SizedBox(width: 16),

            // 텍스트 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜 및 작성자
                  Row(
                    children: [
                      Text(
                        formattedDate,
                        style: AppTextStyles.captionRegular.copyWith(
                          color: AppColorStyles.gray80,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('·'),
                      const SizedBox(width: 4),
                      Text(
                        post.authorNickname,
                        style: AppTextStyles.captionRegular.copyWith(
                          color: AppColorStyles.gray100,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // 제목
                  Text(
                    post.title,
                    style: AppTextStyles.subtitle1Bold.copyWith(
                      color: AppColorStyles.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // 해시태그
                  if (post.hashTags.isNotEmpty) ...[
                    Text(
                      post.hashTags.map((tag) => '#$tag').join(' '),
                      style: AppTextStyles.captionRegular.copyWith(
                        color: AppColorStyles.primary80,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // 댓글 및 좋아요 수
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
                        '${post.commentCount}', // 비정규화된 commentCount 사용
                        style: AppTextStyles.captionRegular.copyWith(
                          color: AppColorStyles.gray100,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        // 사용자의 좋아요 상태에 따라 아이콘 변경
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
                        '${post.likeCount}', // 비정규화된 likeCount 사용
                        style: AppTextStyles.captionRegular.copyWith(
                          color: AppColorStyles.gray100,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
