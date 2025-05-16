import 'dart:io';

import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:flutter/material.dart';

import '../../../auth/domain/model/member.dart';
import '../../../core/styles/app_text_styles.dart';

class ProfileInfo extends StatelessWidget {
  final Member member;
  final bool compact; // 컴팩트 모드 옵션 추가

  const ProfileInfo({
    super.key,
    required this.member,
    this.compact = false, // 기본값은 false
  });

  @override
  Widget build(BuildContext context) {
    // 컴팩트 모드에 따라 크기 조정
    final double imageSize = compact ? 60.0 : 72.0;
    final double iconSize = compact ? 24.0 : 30.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 프로필 사진
            Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    spreadRadius: 2,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _buildProfileImage(),
            ),
            SizedBox(width: compact ? 12 : 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.nickname,
                  style:
                      compact
                          ? AppTextStyles.subtitle1Bold
                          : AppTextStyles.heading6Bold,
                ),
                SizedBox(height: compact ? 2 : 4),
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: AppColorStyles.primary100,
                      size: iconSize,
                    ),
                    SizedBox(width: compact ? 2 : 4),
                    Text(
                      '${member.streakDays} Day',
                      style:
                          compact
                              ? AppTextStyles.subtitle2Regular
                              : AppTextStyles.heading6Regular,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // 소개글 (컴팩트 모드에서는 생략 가능)
        if (!compact && member.description.isNotEmpty) ...[
          const SizedBox(height: 15),
          Text(
            member.description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            softWrap: true,
            overflow: TextOverflow.visible,
            textAlign: TextAlign.start,
          ),
        ],
      ],
    );
  }

  Widget _buildProfileImage() {
    // 이미지 처리 로직은 기존과 동일
    if (member.image.isEmpty) {
      return CircleAvatar(
        radius: compact ? 30 : 36,
        backgroundColor: Colors.grey.shade200,
        child: Icon(
          Icons.person,
          size: compact ? 30 : 36,
          color: Colors.grey.shade400,
        ),
      );
    }

    if (member.image.startsWith('/')) {
      return CircleAvatar(
        radius: compact ? 30 : 36,
        backgroundImage: FileImage(File(member.image)),
        backgroundColor: Colors.grey.shade200,
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('이미지 로딩 오류: $exception');
          return;
        },
      );
    }

    return CircleAvatar(
      radius: compact ? 30 : 36,
      backgroundImage: NetworkImage(member.image),
      backgroundColor: Colors.grey.shade200,
      onBackgroundImageError: (exception, stackTrace) {
        debugPrint('이미지 로딩 오류: $exception');
        return;
      },
    );
  }
}
