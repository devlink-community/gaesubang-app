// lib/map/presentation/components/group_map_member_card.dart
import 'package:devlink_mobile_app/core/component/app_image.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/map/domain/model/group_member_location.dart';
import 'package:flutter/material.dart';

class GroupMapMemberCard extends StatelessWidget {
  final GroupMemberLocation member;
  final VoidCallback onProfileTap;
  final VoidCallback onClose;

  const GroupMapMemberCard({
    super.key,
    required this.member,
    required this.onProfileTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final lastUpdated = member.lastUpdated;
    final lastUpdatedText =
        lastUpdated != null ? _formatLastUpdated(lastUpdated) : '알 수 없음';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AppImage.profile(imagePath: member.imageUrl, size: 40),
            ),
            title: Text(member.nickname, style: AppTextStyles.subtitle1Bold),
            subtitle: Row(
              children: [
                Icon(
                  member.isOnline ? Icons.circle : Icons.circle_outlined,
                  size: 12,
                  color:
                      member.isOnline
                          ? AppColorStyles.success
                          : AppColorStyles.gray80,
                ),
                const SizedBox(width: 4),
                Text(
                  member.isOnline ? '온라인' : '오프라인',
                  style: AppTextStyles.captionRegular.copyWith(
                    color:
                        member.isOnline
                            ? AppColorStyles.success
                            : AppColorStyles.gray80,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '마지막 업데이트: $lastUpdatedText',
                  style: AppTextStyles.captionRegular.copyWith(
                    color: AppColorStyles.gray80,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose,
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap: onProfileTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: AppColorStyles.primary100,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '프로필 보기',
                    style: AppTextStyles.button2Regular.copyWith(
                      color: AppColorStyles.primary100,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 마지막 업데이트 시간 포맷팅
  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inDays}일 전';
    }
  }
}
