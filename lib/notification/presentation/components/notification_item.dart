import 'package:devlink_mobile_app/notification/domain/model/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool showDate; // 날짜 표시 여부 (최근 7일/이전 활동용)

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    this.onDelete,
    this.showDate = false, // 기본값은 false (오늘 알림용)
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red[400],
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 이미지
              _buildProfileImage(),
              const SizedBox(width: 12),

              // 알림 내용
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 보낸 사람
                    Text(
                      notification.senderName,
                      style: TextStyle(
                        fontWeight:
                            notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // 알림 내용
                    Text(
                      notification.description ??
                          _getDefaultDescription(notification.type),
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // 시간 정보
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // 알림 타입에 따른 아이콘
                        _buildTypeIcon(),
                        const SizedBox(width: 4),

                        // 시간 정보
                        Text(
                          _formatTime(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 읽지 않은 알림 표시
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 40,
        height: 40,
        child:
            notification.imageUrl != null
                ? Image.network(
                  notification.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultProfileIcon();
                  },
                )
                : _buildDefaultProfileIcon(),
      ),
    );
  }

  Widget _buildDefaultProfileIcon() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.person, size: 24, color: Colors.grey[600]),
    );
  }

  Widget _buildTypeIcon() {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.like:
        iconData = Icons.favorite;
        iconColor = Colors.red[400]!;
        break;
      case NotificationType.comment:
        iconData = Icons.comment;
        iconColor = Colors.blue[400]!;
        break;
      case NotificationType.follow:
        iconData = Icons.person_add;
        iconColor = Colors.green[400]!;
        break;
      case NotificationType.mention:
        iconData = Icons.alternate_email;
        iconColor = Colors.purple[400]!;
        break;
    }

    return Icon(iconData, size: 12, color: iconColor);
  }

  String _formatTime() {
    final now = TimeFormatter.nowInSeoul();
    final difference = now.difference(notification.createdAt);

    // 이전 활동만 날짜 형식으로 표시 (7일 이상 지난 경우)
    if (showDate && difference.inDays >= 7) {
      return DateFormat('yyyy.MM.dd').format(notification.createdAt);
    } else {
      // 오늘 및 최근 7일은 상대적 시간 표시
      if (difference.inMinutes < 1) {
        return '방금 전';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}분 전';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}시간 전';
      } else {
        return '${difference.inDays}일 전';
      }
    }
  }

  String _getDefaultDescription(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return '회원님의 게시글에 좋아요를 눌렀습니다.';
      case NotificationType.comment:
        return '회원님의 게시글에 댓글을 남겼습니다.';
      case NotificationType.follow:
        return '회원님을 팔로우하기 시작했습니다.';
      case NotificationType.mention:
        return '게시글에서 회원님을 언급했습니다.';
    }
  }
}
