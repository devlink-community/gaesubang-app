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
    // 날짜 포맷터
    final dateFormat = DateFormat('yyyy-MM-dd');
    final formattedDate = dateFormat.format(post.createdAt.toLocal());

    // 이미지 존재 여부 확인
    final hasImage = post.imageUrls.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 - 작성자 정보와 날짜
            Row(
              children: [
                // 프로필 이미지
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColorStyles.primary100,
                        AppColorStyles.primary80,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child:
                      post.userProfileImageUrl.isNotEmpty
                          ? Image.network(
                            post.userProfileImageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: Text(
                                  post.authorNickname.isNotEmpty
                                      ? post.authorNickname[0].toUpperCase()
                                      : 'U',
                                  style: AppTextStyles.subtitle1Bold.copyWith(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  post.authorNickname.isNotEmpty
                                      ? post.authorNickname[0].toUpperCase()
                                      : 'U',
                                  style: AppTextStyles.subtitle1Bold.copyWith(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              );
                            },
                          )
                          : Center(
                            child: Text(
                              post.authorNickname.isNotEmpty
                                  ? post.authorNickname[0].toUpperCase()
                                  : 'U',
                              style: AppTextStyles.subtitle1Bold.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorNickname,
                        style: AppTextStyles.subtitle1Bold.copyWith(
                          fontSize: 14,
                          color: AppColorStyles.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: AppTextStyles.captionRegular.copyWith(
                          color: AppColorStyles.gray80,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // 북마크 아이콘
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    post.isBookmarkedByCurrentUser
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    size: 20,
                    color:
                        post.isBookmarkedByCurrentUser
                            ? AppColorStyles.primary100
                            : AppColorStyles.gray60,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 메인 컨텐츠 영역
            hasImage ? _buildWithImage() : _buildWithoutImage(),

            const SizedBox(height: 16),

            // 하단 - 해시태그와 상호작용
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 해시태그
                if (post.hashTags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children:
                        post.hashTags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColorStyles.primary100.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '#$tag',
                              style: AppTextStyles.captionRegular.copyWith(
                                color: AppColorStyles.primary100,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // 상호작용 버튼들
                Row(
                  children: [
                    _buildInteractionButton(
                      icon:
                          post.isLikedByCurrentUser
                              ? Icons.favorite
                              : Icons.favorite_border,
                      count: post.likeCount,
                      isActive: post.isLikedByCurrentUser,
                      activeColor: Colors.red,
                    ),
                    const SizedBox(width: 24),
                    _buildInteractionButton(
                      icon: Icons.chat_bubble_outline,
                      count: post.commentCount,
                      isActive: false,
                      activeColor: AppColorStyles.primary100,
                    ),
                    const Spacer(),
                    // 더보기 버튼
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColorStyles.gray60,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 이미지가 있는 경우의 컨텐츠 영역
  Widget _buildWithImage() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 텍스트 영역
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                post.title,
                style: AppTextStyles.heading6Bold.copyWith(
                  fontSize: 18,
                  color: AppColorStyles.textPrimary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // 내용 미리보기
              Text(
                post.content,
                style: AppTextStyles.body1Regular.copyWith(
                  color: AppColorStyles.gray100,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // 이미지
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColorStyles.gray40,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            post.imageUrls.first,
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
      ],
    );
  }

  /// 이미지가 없는 경우의 컨텐츠 영역
  Widget _buildWithoutImage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        Text(
          post.title,
          style: AppTextStyles.heading6Bold.copyWith(
            fontSize: 18,
            color: AppColorStyles.textPrimary,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 8),

        // 내용 미리보기
        Text(
          post.content,
          style: AppTextStyles.body1Regular.copyWith(
            color: AppColorStyles.gray100,
            height: 1.4,
          ),
          maxLines: 3, // 이미지 없을 때는 한 줄 더 표시
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 상호작용 버튼 (좋아요, 댓글)
  Widget _buildInteractionButton({
    required IconData icon,
    required int count,
    required bool isActive,
    required Color activeColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: isActive ? activeColor : AppColorStyles.gray80,
        ),
        const SizedBox(width: 6),
        Text(
          count.toString(),
          style: AppTextStyles.captionRegular.copyWith(
            color: isActive ? activeColor : AppColorStyles.gray80,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
