// lib/community/presentation/components/post_list_item.dart

import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:flutter/material.dart';

class PostListItem extends StatelessWidget {
  const PostListItem({
    super.key,
    required this.post,
    required this.onTap,
  });

  final Post post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 이미지 URL 결정 (빈 리스트면 기본 이미지 사용)
    final imageUrl = post.imageUrls.isNotEmpty 
        ? post.imageUrls.first 
        : 'https://i.namu.wiki/i/R0AhIJhNi8fkU2Al72pglkrT8QenAaCJd1as-d_iY6MC8nub1iI5VzIqzJlLa-1uzZm--TkB-KHFiT-P-t7bEg.webp';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // 이 속성이 중요합니다 - 투명한 부분까지 터치 감지
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, // 배경색 추가
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200), // 경계선 추가
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 - 원하는 크기로 조정 가능
            Container(
              width: 100, // 원하는 너비로 조정
              height: 100, // 원하는 높이로 조정
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColorStyles.gray60,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
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
                  Text(
                    '${post.createdAt.toLocal().year}-${post.createdAt.toLocal().month.toString().padLeft(2, '0')}-${post.createdAt.toLocal().day.toString().padLeft(2, '0')} · ${post.member.nickname}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                  const SizedBox(height: 4),

                  // 제목
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // 해시태그
                  Text(
                    post.hashTags.join(' '),
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // 댓글 및 좋아요 수
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.comment, size: 16),
                        const SizedBox(width: 4),
                        Text('${post.comment.length}'),
                        const SizedBox(width: 12),
                        const Icon(Icons.favorite_border, size: 16),
                        const SizedBox(width: 4),
                        Text('${post.like.length}'),
                      ],
                    ),
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