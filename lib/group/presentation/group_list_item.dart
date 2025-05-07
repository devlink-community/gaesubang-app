import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:flutter/material.dart';

class GroupListItem extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;

  const GroupListItem({super.key, required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.grey[100],
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 그룹 이미지 영역
              AspectRatio(
                aspectRatio: 4 / 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      group.imageUrl != null
                          ? (group.imageUrl!.startsWith('assets/') ||
                                  group.imageUrl!.startsWith('asset/'))
                              ? Image.asset(
                                group.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.image, size: 40);
                                },
                              )
                              : Image.network(
                                group.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.image, size: 40);
                                },
                              )
                          : const Icon(Icons.image, size: 40),
                ),
              ),
              const SizedBox(height: 12),

              // 그룹 제목
              Text(
                group.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // 태그 목록
              Wrap(
                spacing: 6,
                children:
                    group.hashTags.map((tag) {
                      return Text(
                        '#${tag.content}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 8),

              // 멤버 정보
              Row(
                children: [
                  const Icon(Icons.people, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    '${group.memberCount}명 / ${group.limitMemberCount}명',
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
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
