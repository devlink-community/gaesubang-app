import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:flutter/material.dart';

class GroupListItem extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;
  final bool isCurrentMemberJoined;

  const GroupListItem({
    super.key,
    required this.group,
    required this.onTap,
    this.isCurrentMemberJoined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 프로필 이미지
                  Container(
                    // width: 100,
                    // height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColorStyles.gray60,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child:
                        group.imageUrl != null
                            ? group.imageUrl!.startsWith('assets/') ||
                                    group.imageUrl!.startsWith('asset/')
                                ? Image.asset(
                                  group.imageUrl!,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.image,
                                      size: 30,
                                      color: AppColorStyles.gray60,
                                    );
                                  },
                                )
                                : Image.network(
                                  group.imageUrl!,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.image,
                                      size: 30,
                                      color: AppColorStyles.gray60,
                                    );
                                  },
                                )
                            : const Icon(
                              Icons.image,
                              size: 30,
                              color: AppColorStyles.gray60,
                            ),
                  ),
                  const SizedBox(width: 14),

                  // 스터디 제목 및 태그
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.name,
                                style: AppTextStyles.subtitle1Bold.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // 가입된 그룹이면 "참여중" 배지 표시
                            if (isCurrentMemberJoined)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColorStyles.primary100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '참여중',
                                  style: AppTextStyles.captionRegular.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 6,
                          children: [
                            ...group.hashTags
                                .take(3)
                                .map(
                                  (tag) => Text(
                                    '#${tag.content}',
                                    style: AppTextStyles.body1Regular.copyWith(
                                      color: AppColorStyles.gray100,
                                    ),
                                  ),
                                ),

                            // 3개 초과 시 '외 N개' 표시
                            if (group.hashTags.length > 3)
                              Text(
                                '외 ${group.hashTags.length - 3}',
                                style: AppTextStyles.body1Regular.copyWith(
                                  color: AppColorStyles.gray80,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.people,
                              size: 14,
                              color: AppColorStyles.primary100,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${group.memberCount}명 / ${group.limitMemberCount}명',
                              style: AppTextStyles.body2Regular.copyWith(
                                color: AppColorStyles.primary100,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
