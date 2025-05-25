import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MemberAttendanceCard extends StatelessWidget {
  final String userName;
  final String userId;
  final String? profileUrl;
  final int totalMinutes;
  final int rank;

  const MemberAttendanceCard({
    super.key,
    required this.userName,
    required this.userId,
    this.profileUrl,
    required this.totalMinutes,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColorByTime(totalMinutes);
    final icon = _getIconByTime(totalMinutes);

    return InkWell(
      onTap: () {
        // 사용자 ID가 있을 때만 네비게이션 수행
        if (userId.isNotEmpty) {
          context.push('/user/$userId/profile');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 순위
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: rank <= 3 ? _getRankColor(rank) : AppColorStyles.gray80,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: AppTextStyles.captionRegular.copyWith(
                    color: AppColorStyles.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 프로필 - 프로필 이미지 사용 또는 이니셜 표시
            _buildProfileAvatar(color),
            const SizedBox(width: 16),

            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        userName,
                        style: AppTextStyles.subtitle1Bold,
                      ),
                      if (rank == 1) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.emoji_events,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '학습시간: ${_formatMinutes(totalMinutes)}',
                    style: AppTextStyles.body2Regular.copyWith(
                      color: AppColorStyles.gray100,
                    ),
                  ),
                ],
              ),
            ),

            // 상태 아이콘
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),

            // 프로필 이동 아이콘 추가
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: AppColorStyles.gray80,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // 프로필 아바타 빌드 (URL 또는 이니셜)
  Widget _buildProfileAvatar(Color color) {
    // 프로필 URL이 있으면 네트워크 이미지 사용
    if (profileUrl != null && profileUrl!.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 2,
          ),
          image: DecorationImage(
            image: NetworkImage(profileUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // 프로필 URL이 없으면 이니셜 표시
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getInitial(userName),
          style: AppTextStyles.subtitle1Bold.copyWith(
            color: AppColorStyles.white,
          ),
        ),
      ),
    );
  }

  // 유틸리티 메서드들
  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // 금
      case 2:
        return Colors.grey[400]!; // 은
      case 3:
        return Colors.brown[400]!; // 동
      default:
        return AppColorStyles.gray80;
    }
  }

  Color _getColorByTime(int minutes) {
    if (minutes >= 240) {
      return AppColorStyles.primary100; // 4시간 이상
    } else if (minutes >= 120) {
      return AppColorStyles.primary80; // 2시간 이상
    } else if (minutes >= 30) {
      return AppColorStyles.primary60; // 30분 이상
    } else {
      return AppColorStyles.gray100; // 30분 미만
    }
  }

  IconData _getIconByTime(int minutes) {
    if (minutes >= 240) {
      return Icons.star; // 4시간 이상
    } else if (minutes >= 120) {
      return Icons.thumb_up; // 2시간 이상
    } else if (minutes >= 30) {
      return Icons.check_circle; // 30분 이상
    } else {
      return Icons.access_time; // 30분 미만
    }
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0) {
      return '$hours시간 ${mins > 0 ? "$mins분" : ""}';
    } else {
      return '$mins분';
    }
  }

  // 이름에서 이니셜 추출
  String _getInitial(String name) {
    if (name.isEmpty) return '?';
    return name.substring(0, 1);
  }
}
