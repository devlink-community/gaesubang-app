import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';

@freezed
class Notification with _$Notification {
  const Notification({
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

  final String id;
  final String userId;
  final NotificationType type;
  final String targetId;
  final String senderName;
  final DateTime createdAt;
  final bool isRead;
  final String? description;
  final String? imageUrl;
}

enum NotificationType { like, comment, follow, mention }
