import 'package:devlink_mobile_app/group/domain/model/member_timer_status.dart';
import 'package:flutter/material.dart';

import '../../../../core/styles/app_color_styles.dart';
import '../../../../core/styles/app_text_styles.dart';

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
                          ? AppColorStyles.primary100
                          : AppColorStyles.gray40,
                  width: 2,
                ),
                boxShadow:
                    status == MemberTimerStatus.active
                        ? [
                          BoxShadow(
                            color: AppColorStyles.primary80.withOpacity(0.15),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                        : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child:
                    imageUrl.isNotEmpty
                        ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 24,
                              color: AppColorStyles.gray60,
                            );
                          },
                        )
                        : Icon(
                          Icons.person,
                          size: 24,
                          color: AppColorStyles.gray60,
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
                    color: AppColorStyles.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColorStyles.success.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),

            if (status == MemberTimerStatus.sleeping)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColorStyles.gray80,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),

        // 타이머 표시 - 상태에 따라 다른 위젯 표시
        status == MemberTimerStatus.sleeping
            ? Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColorStyles.gray40.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.nightlight_round,
                    size: 10,
                    color: AppColorStyles.gray80,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '휴식중',
                    style: AppTextStyles.captionRegular.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColorStyles.gray80,
                    ),
                  ),
                ],
              ),
            )
            : Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColorStyles.primary100.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                timeDisplay.toString(),
                style: AppTextStyles.captionRegular.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColorStyles.primary100,
                ),
              ),
            ),
      ],
    );
  }
}
