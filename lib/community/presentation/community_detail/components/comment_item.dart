// lib/community/presentation/community_detail/components/comment_item.dart
import 'package:devlink_mobile_app/community/domain/model/comment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommentItem extends StatelessWidget {
  const CommentItem({super.key, required this.comment});
  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy.MM.dd');
    final formattedDate = dateFormat.format(comment.createdAt);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 이미지
          CircleAvatar(
            backgroundImage: NetworkImage(comment.userProfileImage),
            radius: 16,
          ),
          const SizedBox(width: 12),
          
          // 댓글 내용 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 사용자 이름 및 날짜
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
                
                // 댓글 내용
                Text(
                  comment.text,
                  style: const TextStyle(fontSize: 14),
                ),
                
                // 좋아요 영역
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      // 댓글 좋아요 기능은 아직 구현되지 않음
                    },
                    icon: const Icon(Icons.favorite_border, size: 14),
                    label: Text(
                      comment.likeCount.toString(),
                      style: const TextStyle(fontSize: 12),
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