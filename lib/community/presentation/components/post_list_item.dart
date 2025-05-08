import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:flutter/material.dart';

class PostListItem extends StatelessWidget {
  const PostListItem({super.key, required this.post, required this.onTap});

  final Post post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColorStyles.gray60,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        post.image,
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
    // title: Text(post.title),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${post.createdAt.toLocal().year}-${post.createdAt.toLocal().month.toString().padLeft(2, '0')}-${post.createdAt.toLocal().day.toString().padLeft(2, '0')} · ${post.member.nickname}',
          style: TextStyle(fontSize: 12),
        ),
        Text(post.title),
      ],
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          post.hashTag.map((e) => e.content).join(' '),
          style: TextStyle(fontSize: 12),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.comment, size: 16),
              const SizedBox(width: 4),
              Text('${post.comment.length}'),
              const SizedBox(width: 8),
              const Icon(Icons.favorite_border, size: 16),
              const SizedBox(width: 4),
              Text('${post.like.length}'),
            ],
          ),
        ),
      ],
    ),

    onTap: onTap,
  );
}
