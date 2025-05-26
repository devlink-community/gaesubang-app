// lib/group/data/data_source/group_chat_firebase_data_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlink_mobile_app/core/utils/api_call_logger.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:devlink_mobile_app/group/data/data_source/group_chat_data_source.dart';

class GroupChatFirebaseDataSource implements GroupChatDataSource {
  final FirebaseFirestore _firestore;

  GroupChatFirebaseDataSource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // 그룹 채팅 컬렉션 참조 가져오기
  CollectionReference<Map<String, dynamic>> _getMessagesCollection(
    String groupId,
  ) {
    return _firestore.collection('groups').doc(groupId).collection('messages');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGroupMessages(
    String groupId, {
    int limit = 50,
  }) async {
    return ApiCallDecorator.wrap(
      'GroupChatFirebase.fetchGroupMessages',
      () async {
        try {
          final messagesSnapshot =
              await _getMessagesCollection(
                groupId,
              ).orderBy('timestamp', descending: true).limit(limit).get();

          return messagesSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        } catch (e) {
          AppLogger.error(
            '채팅 메시지 조회 오류',
            tag: 'GroupChatFirebase',
            error: e,
          );
          throw Exception('채팅 메시지를 불러오는데 실패했습니다');
        }
      },
      params: {'groupId': groupId, 'limit': limit},
    );
  }

  @override
  Future<Map<String, dynamic>> sendMessage(
    String groupId,
    String content,
    String senderId,
    String senderName,
    String? senderImage,
  ) async {
    return ApiCallDecorator.wrap(
      'GroupChatFirebase.sendMessage',
      () async {
        try {
          // 새 메시지 데이터 준비
          final messageData = {
            'groupId': groupId,
            'content': content,
            'senderId': senderId,
            'senderName': senderName,
            'senderImage': senderImage,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          };

          // Firestore에 메시지 추가
          final docRef = await _getMessagesCollection(groupId).add(messageData);

          // 생성된 메시지 반환
          final newMessage = {...messageData, 'id': docRef.id};

          newMessage['timestamp'] = Timestamp.fromDate(
            TimeFormatter.nowInSeoul(),
          );

          return newMessage;
        } catch (e) {
          AppLogger.error(
            '메시지 전송 오류',
            tag: 'GroupChatFirebase',
            error: e,
          );
          throw Exception('메시지 전송에 실패했습니다');
        }
      },
      params: {
        'groupId': groupId,
        'senderId': senderId,
      },
    );
  }

  @override
  Stream<List<Map<String, dynamic>>> streamGroupMessages(String groupId) {
    try {
      return _getMessagesCollection(groupId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();
          });
    } catch (e) {
      AppLogger.error(
        '메시지 스트림 구독 오류',
        tag: 'GroupChatFirebase',
        error: e,
      );
      // 스트림 에러 처리는 리포지토리에서 Result로 변환
      throw Exception('메시지 스트림 구독에 실패했습니다');
    }
  }

  @override
  Future<void> markMessagesAsRead(String groupId, String userId) async {
    return ApiCallDecorator.wrap(
      'GroupChatFirebase.markMessagesAsRead',
      () async {
        try {
          // 🔧 수정: 복잡한 쿼리 대신 단순화
          final unreadMessages =
              await _getMessagesCollection(groupId)
                  .where('isRead', isEqualTo: false)
                  // 🔧 senderId 조건 제거하여 인덱스 요구사항 단순화
                  .get();

          // 메시지가 없으면 바로 반환
          if (unreadMessages.docs.isEmpty) {
            return;
          }

          // 일괄 업데이트를 위한 쓰기 일괄 처리
          final batch = _firestore.batch();

          for (final doc in unreadMessages.docs) {
            final data = doc.data();
            // 🆕 추가: 자신이 보낸 메시지는 제외
            if (data['senderId'] != userId) {
              batch.update(doc.reference, {'isRead': true});
            }
          }

          // 일괄 처리 실행
          await batch.commit();
        } catch (e) {
          AppLogger.error(
            '메시지 읽음 처리 오류',
            tag: 'GroupChatFirebase',
            error: e,
          );
          throw Exception('메시지 읽음 처리에 실패했습니다');
        }
      },
      params: {'groupId': groupId, 'userId': userId},
    );
  }
}
