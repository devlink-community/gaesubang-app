// lib/group/data/data_source/group_chat_data_source.dart
abstract interface class GroupChatDataSource {
  /// 그룹 채팅 메시지 목록 조회
  Future<List<Map<String, dynamic>>> fetchGroupMessages(
    String groupId, {
    int limit = 50,
  });
  
  /// 채팅 메시지 전송
  Future<Map<String, dynamic>> sendMessage(
    String groupId,
    String content,
    String senderId,
    String senderName,
    String? senderImage,
  );
  
  /// 실시간 채팅 메시지 스트림 구독
  Stream<List<Map<String, dynamic>>> streamGroupMessages(String groupId);
  
  /// 메시지 읽음 상태 업데이트
  Future<void> markMessagesAsRead(String groupId, String userId);
}