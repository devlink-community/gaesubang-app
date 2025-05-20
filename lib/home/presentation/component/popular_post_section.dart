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
        const SizedBox(height: 12),
        _buildPostList(),
      ],
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      children: [
        Icon(Icons.check_circle, color: AppColorStyles.primary80, size: 20),
        const SizedBox(width: 8),
        Text('인기 게시글', style: AppTextStyles.subtitle1Bold),
      ],
    );
  }

  Widget _buildPostList() {
    return posts.when(
      data: (data) {
        if (data.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('인기 게시글이 없습니다')),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final post = data[index];
            return _buildPostItem(post);
          },
        );
      },
      loading:
          () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, stack) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '인기 게시글을 불러오는데 실패했습니다: $error',
                style: AppTextStyles.body1Regular.copyWith(
                  color: AppColorStyles.error,
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildPostItem(Post post) {
    // 날짜 포맷 설정
    final dateFormat = DateFormat('yy-MM-dd');
    final formattedDate = dateFormat.format(post.createdAt);

    // 작성자
    final authorName = post.authorNickname;

    return InkWell(
      onTap: () {
        if (post.id.isNotEmpty) {
          // ID가 비어있지 않은지 확인
          print('게시글 클릭: ${post.id}');
          onTapPost(post.id);
        } else {
          print('게시글 ID가 비어 있습니다.');
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 정보 (날짜 + 작성자)
              Row(
                children: [
                  Text(
                    '$formattedDate · $authorName',
                    style: AppTextStyles.captionRegular.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 제목
              Text(
                post.title,
                style: AppTextStyles.subtitle1Bold,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // 태그
              if (post.hashTags.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children:
                      post.hashTags.map((tag) {
                        return Text(
                          '#$tag',
                          style: AppTextStyles.captionRegular.copyWith(
                            color: AppColorStyles.primary80,
                          ),
                        );
                      }).toList(),
                ),
              const SizedBox(height: 8),

              // 하단 정보 (댓글 수 + 좋아요 수)
              Row(
                children: [
                  Icon(
                    Icons.comment_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.comment.length}',
                    style: AppTextStyles.captionRegular,
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.favorite_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.like.length}',
                    style: AppTextStyles.captionRegular,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
