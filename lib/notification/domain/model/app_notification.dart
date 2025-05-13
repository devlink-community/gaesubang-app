import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';

// ignore_for_file: annotate_overrides
@freezed
class AppNotification with _$AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String targetId;
  final String senderName;
  final DateTime createdAt;
  final bool isRead;
  final String? description;
  final String? imageUrl;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.targetId,
    required this.senderName,
    required this.createdAt,
    this.isRead = false,
    this.description,
    this.imageUrl,
  });
}

enum NotificationType { like, comment, follow, mention }
