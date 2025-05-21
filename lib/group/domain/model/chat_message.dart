// lib/group/domain/model/chat_message.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';

/// 채팅 메시지 도메인 모델
@freezed
class ChatMessage with _$ChatMessage {
  const ChatMessage({
    required this.id,
    required this.groupId,
    required this.content,
    required this.senderId,
    required this.senderName,
    this.senderImage,
    required this.timestamp,
    this.isRead = false,
  });
  
  final String id;
  final String groupId;
  final String content;
  final String senderId;
  final String senderName;
  final String? senderImage;
  final DateTime timestamp;
  final bool isRead;
}