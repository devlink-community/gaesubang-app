// lib/community/presentation/community_detail/components/comment_item.dart
import 'package:devlink_mobile_app/community/domain/model/comment.dart';
import 'package:devlink_mobile_app/community/presentation/community_detail/community_detail_action.dart';
import 'package:devlink_mobile_app/core/component/app_image.dart'; // 추가: AppImage 임포트
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommentItem extends StatelessWidget {
  const CommentItem({super.key, required this.comment, required this.onAction});

  final Comment comment;
  final Function(CommunityDetailAction) onAction;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy.MM.dd');
    final formattedDate = dateFormat.format(comment.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 이미지 - AppImage 컴포넌트 사용
          AppImage.profile(
            imagePath: comment.userProfileImage,
            size: 32,
            backgroundColor: Colors.grey.shade200,
            foregroundColor: Colors.grey.shade400,
          ),
          const SizedBox(width: 12),

          // 댓글 내용 영역 (변경 없음)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 사용자 이름 및 날짜 (변경 없음)
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // 댓글 내용 (변경 없음)
                Text(comment.text, style: const TextStyle(fontSize: 14)),

                // 좋아요 영역 (변경 없음)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      // 댓글 좋아요 액션 호출 (id 필드 사용)
                      onAction(
                        CommunityDetailAction.toggleCommentLike(comment.id),
                      );
                    },
                    icon: Icon(
                      comment.isLikedByCurrentUser
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 14,
                      color:
                          comment.isLikedByCurrentUser
                              ? Colors.red
                              : Colors.grey,
                    ),
                    label: Text(
                      comment.likeCount.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            comment.isLikedByCurrentUser
                                ? Colors.red
                                : Colors.grey,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
