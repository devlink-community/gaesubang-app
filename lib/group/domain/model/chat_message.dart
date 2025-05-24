// lib/group/domain/model/chat_message.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';

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
    required this.isRead,
  });

  @override
  final String id;
  @override
  final String groupId;
  @override
  final String content;
  @override
  final String senderId;
  @override
  final String senderName;
  @override
  final String? senderImage;
  @override
  final DateTime timestamp;
  @override
  final bool isRead;
}
