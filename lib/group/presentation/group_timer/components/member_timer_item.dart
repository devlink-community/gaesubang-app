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
      children: [
        // 원형 프로필 이미지
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child:
                imageUrl.isNotEmpty
                    ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, size: 30);
                      },
                    )
                    : const Icon(Icons.person, size: 30),
          ),
        ),
        const SizedBox(height: 4),

        // 타이머 상태 표시
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status == MemberTimerStatus.sleeping ? 'zzz' : timeDisplay,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

enum MemberTimerStatus {
  active, // 타이머 활성화 상태
  sleeping, // 잠자는 상태 (비활성)
  inactive, // 비활성 상태
}
