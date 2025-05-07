import 'package:flutter/material.dart';

import '../../../auth/domain/model/member.dart';

class ProfileInfo extends StatelessWidget {
  final Member member;

  const ProfileInfo({Key? key, required this.member}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 테마에서 primaryColor를 불러와서 스테이크 아이콘 색으로 사용
    final primary = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 프로필 사진
              CircleAvatar(
                radius: 36,
                backgroundImage: NetworkImage(member.image),
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(width: 16),
              // 닉네임 + 연속일(스테이크) 표시
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.nickname,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: primary,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      // Member 모델에 streakDays 필드가 없다면 원하는 텍스트로 바꿔 주세요
                      Text(
                        '1 Day',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // 소개글
          if (member.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              member.description,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
