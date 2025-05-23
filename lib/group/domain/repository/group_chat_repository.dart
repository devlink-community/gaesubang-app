import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/chat_message.dart';

abstract interface class GroupChatRepository {
  /// 그룹 채팅 메시지 목록 조회
  Future<Result<List<ChatMessage>>> getGroupMessages(
    String groupId, {
    int limit = 50,
  });

  /// 채팅 메시지 전송
  Future<Result<ChatMessage>> sendMessage(String groupId, String content);

  /// 🆕 봇 메시지 전송 (전용 메서드)
  Future<Result<ChatMessage>> sendBotMessage(
    String groupId,
    String content,
    String botId,
    String botName,
  );

  /// 실시간 채팅 메시지 스트림 구독
  Stream<Result<List<ChatMessage>>> getGroupMessagesStream(String groupId);

  /// 메시지 읽음 상태 업데이트
  Future<Result<void>> markMessagesAsRead(String groupId);
}
