import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';

// ignore_for_file: annotate_overrides
@freezed
class AppNotification with _$AppNotification {
  final String id;
  final String userId; // 수신자 ID (알림을 받는 사용자)
  final NotificationType type;
  final String targetId;
  final String senderName;
  final String? senderId; // 발송자 ID 추가 (nullable로 시작)
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
    this.senderId, // 선택적 파라미터로 추가
    required this.createdAt,
    this.isRead = false,
    this.description,
    this.imageUrl,
  });

  /// 발송자 ID 가져오기 (안전한 접근)
  /// 1. senderId가 있고 비어있지 않으면 senderId 반환
  /// 2. 그렇지 않으면 userId 반환 (후방 호환성)
  /// 3. userId도 비어있으면 'unknown' 반환 (최종 안전장치)
  String get safeSenderId {
    // senderId가 null이 아니고 비어있지 않은 경우
    if (senderId != null && senderId!.trim().isNotEmpty) {
      return senderId!.trim();
    }

    // userId가 비어있지 않은 경우 (후방 호환성)
    if (userId.trim().isNotEmpty) {
      return userId.trim();
    }

    // 최종 안전장치
    return 'unknown';
  }

  /// 실제 발송자 ID가 있는지 확인
  /// senderId가 null이 아니고 비어있지 않은 경우에만 true
  bool get hasSenderId =>
      senderId != null &&
      senderId!.trim().isNotEmpty &&
      senderId!.trim() != 'unknown';

  /// 네비게이션용 발송자 ID (null 반환 가능)
  /// 실제 senderId가 있을 때만 반환, 없으면 null
  /// (follow 타입 등에서 senderId가 필수인 경우 사용)
  String? get navigationSenderId => hasSenderId ? senderId!.trim() : null;
}

enum NotificationType { like, comment, follow, mention }
