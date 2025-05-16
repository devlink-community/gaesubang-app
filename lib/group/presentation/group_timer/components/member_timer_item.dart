// lib/group/presentation/group_timer/components/member_timer_item.dart
import 'package:devlink_mobile_app/core/component/app_image.dart';
import 'package:devlink_mobile_app/group/domain/model/member_timer_status.dart';
import 'package:flutter/material.dart';

class MemberTimerItem extends StatelessWidget {
  const MemberTimerItem({
    super.key,
    required this.imageUrl,
    required this.status,
    required this.timeDisplay,
  });

  final String imageUrl;
  final MemberTimerStatus status;
  final String timeDisplay;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 원형 프로필 이미지
        Stack(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      status == MemberTimerStatus.active
                          ? const Color(0xFF8080FF)
                          : const Color(0xFFE0E0E0),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: AppImage.profile(
                  imagePath: imageUrl,
                  size: 50,
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: Colors.grey.shade400,
                ),
              ),
            ),

            // 상태 표시 아이콘 (활성 상태인 경우)
            if (status == MemberTimerStatus.active)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),

            // 잠자는 상태 아이콘
            if (status == MemberTimerStatus.sleeping)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),

        // 타이머 표시
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color:
                status == MemberTimerStatus.sleeping
                    ? Colors.grey.shade200
                    : const Color(0xFFE6E6FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status == MemberTimerStatus.sleeping ? 'zzz' : timeDisplay,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color:
                  status == MemberTimerStatus.sleeping
                      ? Colors.grey
                      : const Color(0xFF8080FF),
            ),
          ),
        ),
      ],
    );
  }
}
